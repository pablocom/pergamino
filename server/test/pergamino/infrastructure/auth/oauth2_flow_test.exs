defmodule Pergamino.Infrastructure.Auth.OAuth2FlowTest do
  use ExUnit.Case, async: false

  import Swoosh.TestAssertions

  alias Pergamino.Domain.EmailAddress

  alias Pergamino.Infrastructure.Auth.{
    AuthorizationCodeGenerator,
    AuthorizationCodeStore,
    OAuth2Flow,
    TokenGenerator
  }

  setup do
    {:ok, email} = EmailAddress.create("test@example.com")
    verifier = "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"

    challenge =
      :crypto.hash(:sha256, verifier)
      |> Base.url_encode64(padding: false)

    {code, expires_at} = AuthorizationCodeGenerator.generate()
    :ok = AuthorizationCodeStore.store(code, expires_at, email, challenge)

    %{
      email: email,
      code: code,
      verifier: verifier,
      challenge: challenge
    }
  end

  describe "initiate/1" do
    test "sends verification email with deeplink containing authorization code", %{
      challenge: challenge
    } do
      params = %{
        email: "test@example.com",
        code_challenge: challenge
      }

      assert :ok = OAuth2Flow.initiate(params)

      assert_email_sent(fn sent_email ->
        assert sent_email.to == [{"", "test@example.com"}]
        assert sent_email.from == {"", "noreply@pergamino.dev"}
        assert sent_email.subject == "Complete Your Device Setup"
        assert sent_email.text_body =~ "pergamino://bind?code="
        true
      end)
    end

    test "returns error for invalid email format", %{challenge: challenge} do
      params = %{
        email: "not-an-email",
        code_challenge: challenge
      }

      assert {:error, :invalid_email} = OAuth2Flow.initiate(params)
      assert_no_email_sent()
    end

    test "returns error for empty email", %{challenge: challenge} do
      params = %{
        email: "",
        code_challenge: challenge
      }

      assert {:error, :invalid_email} = OAuth2Flow.initiate(params)
      assert_no_email_sent()
    end

    test "normalizes email to lowercase before sending", %{challenge: challenge} do
      params = %{
        email: "Test@Example.COM",
        code_challenge: challenge
      }

      OAuth2Flow.initiate(params)

      assert_email_sent(fn sent_email ->
        sent_email.to == [{"", "test@example.com"}]
      end)
    end
  end

  describe "exchange_authorization_code/1" do
    test "successfully exchanges code for access and refresh tokens", %{
      code: code,
      verifier: verifier
    } do
      params = %{code: code, code_verifier: verifier}

      assert {:ok, response} = OAuth2Flow.exchange_authorization_code(params)

      assert %{
               access_token: access_token,
               refresh_token: refresh_token,
               token_type: "Bearer",
               expires_in: 900
             } = response

      assert is_binary(access_token)
      assert is_binary(refresh_token)

      assert {:ok, access_claims} = TokenGenerator.verify(access_token)
      assert access_claims["email"] == "test@example.com"
      assert access_claims["typ"] == "access"

      assert {:ok, refresh_claims} = TokenGenerator.verify_refresh_token(refresh_token)
      assert refresh_claims["email"] == "test@example.com"
      assert refresh_claims["typ"] == "refresh"
    end

    test "returns error for invalid authorization code" do
      params = %{code: "invalid_code", code_verifier: "some_verifier"}

      assert {:error, :invalid_authorization_code} =
               OAuth2Flow.exchange_authorization_code(params)
    end

    test "returns error for invalid code_verifier", %{code: code} do
      params = %{code: code, code_verifier: "wrong_verifier"}

      assert {:error, :invalid_authorization_code} =
               OAuth2Flow.exchange_authorization_code(params)
    end

    test "code can only be used once", %{code: code, verifier: verifier} do
      params = %{code: code, code_verifier: verifier}

      assert {:ok, _} = OAuth2Flow.exchange_authorization_code(params)

      assert {:error, :invalid_authorization_code} =
               OAuth2Flow.exchange_authorization_code(params)
    end

    test "returns error when email from Redis is invalid" do
      {code, expires_at} = AuthorizationCodeGenerator.generate()
      verifier = "test_verifier"

      challenge =
        :crypto.hash(:sha256, verifier)
        |> Base.url_encode64(padding: false)

      key = "auth_code:#{code}"
      ttl_seconds = DateTime.diff(expires_at, DateTime.utc_now(), :second) |> max(0)

      invalid_json =
        Jason.encode!(%{
          email: "not-an-email",
          code_challenge: challenge
        })

      Redix.command(:redix, ["SETEX", key, ttl_seconds, invalid_json])

      params = %{code: code, code_verifier: verifier}

      assert {:error, :service_unavailable} = OAuth2Flow.exchange_authorization_code(params)
    end
  end

  describe "refresh_access_token/1" do
    test "successfully refreshes access token", %{email: email} do
      {:ok, refresh_token} = TokenGenerator.generate_refresh_token(email)

      assert {:ok, response} = OAuth2Flow.refresh_access_token(refresh_token)

      assert %{
               access_token: new_access_token,
               refresh_token: new_refresh_token,
               token_type: "Bearer",
               expires_in: 900
             } = response

      assert is_binary(new_access_token)
      assert is_binary(new_refresh_token)
      assert new_refresh_token != refresh_token

      assert {:ok, claims} = TokenGenerator.verify(new_access_token)
      assert claims["email"] == "test@example.com"
    end

    test "returns error for invalid refresh token" do
      assert {:error, :invalid_refresh_token} =
               OAuth2Flow.refresh_access_token("invalid.token.here")
    end

    test "returns error for expired refresh token" do
      expired_token =
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjEsImlhdCI6MX0.invalid"

      assert {:error, :invalid_refresh_token} =
               OAuth2Flow.refresh_access_token(expired_token)
    end

    test "issues new refresh token with different jti", %{email: email} do
      {:ok, refresh_token1} = TokenGenerator.generate_refresh_token(email)

      assert {:ok, response} = OAuth2Flow.refresh_access_token(refresh_token1)

      {:ok, claims1} = TokenGenerator.verify_refresh_token(refresh_token1)
      {:ok, claims2} = TokenGenerator.verify_refresh_token(response.refresh_token)

      assert claims1["jti"] != claims2["jti"]
    end

    test "old refresh token still works until expiry (no revocation)", %{email: email} do
      {:ok, refresh_token} = TokenGenerator.generate_refresh_token(email)

      assert {:ok, _response1} = OAuth2Flow.refresh_access_token(refresh_token)
      assert {:ok, _response2} = OAuth2Flow.refresh_access_token(refresh_token)
    end

    test "returns error when email in token is invalid" do
      jwt_secret_key = Application.fetch_env!(:pergamino, :jwt_secret_key)
      signer = Joken.Signer.create("HS256", jwt_secret_key)

      claims = %{
        "email" => "not-an-email",
        "typ" => "refresh",
        "aud" => "pergamino",
        "iss" => "pergamino",
        "exp" => DateTime.utc_now() |> DateTime.add(7_776_000, :second) |> DateTime.to_unix(),
        "iat" => DateTime.utc_now() |> DateTime.to_unix()
      }

      {:ok, malformed_token, _} = Joken.encode_and_sign(claims, signer)

      assert {:error, :invalid_refresh_token} =
               OAuth2Flow.refresh_access_token(malformed_token)
    end
  end
end
