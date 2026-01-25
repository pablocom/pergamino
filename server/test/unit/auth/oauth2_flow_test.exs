defmodule Unit.Auth.OAuth2FlowTest do
  use ExUnit.Case, async: true

  import Mox

  alias Pergamino.Domain.EmailAddress
  alias Pergamino.Infrastructure.Auth.OAuth2Flow
  alias Pergamino.Infrastructure.Auth.AuthorizationCodeStoreMock
  alias Pergamino.Infrastructure.Messaging.EmailSenderMock

  setup :verify_on_exit!

  setup do
    Application.put_env(:pergamino, :authorization_code_store, AuthorizationCodeStoreMock)
    Application.put_env(:pergamino, :email_sender, EmailSenderMock)

    on_exit(fn ->
      Application.delete_env(:pergamino, :authorization_code_store)
      Application.delete_env(:pergamino, :email_sender)
    end)

    :ok
  end

  describe "initiate/1" do
    test "successfully initiates OAuth2 flow with valid params" do
      email = "test@example.com"
      challenge = "test_challenge"

      expect(AuthorizationCodeStoreMock, :store, fn code, expires_at, email_obj, ^challenge ->
        assert is_binary(code)
        assert %DateTime{} = expires_at
        assert %EmailAddress{address: ^email} = email_obj
        :ok
      end)

      expect(EmailSenderMock, :send_verification_email, fn email_obj, deeplink ->
        assert %EmailAddress{address: ^email} = email_obj
        assert String.starts_with?(deeplink, "pergamino://bind?code=")
        {:ok, %{}}
      end)

      params = %{email: email, code_challenge: challenge}

      assert :ok = OAuth2Flow.initiate(params)
    end

    test "returns error for invalid email format" do
      params = %{email: "not-an-email", code_challenge: "challenge"}

      assert {:error, :invalid_email} = OAuth2Flow.initiate(params)
    end

    test "returns error when code store fails" do
      expect(AuthorizationCodeStoreMock, :store, fn _, _, _, _ ->
        {:error, :redis_unavailable}
      end)

      params = %{email: "test@example.com", code_challenge: "challenge"}

      assert {:error, :service_unavailable} = OAuth2Flow.initiate(params)
    end

    test "returns error when email sending fails" do
      expect(AuthorizationCodeStoreMock, :store, fn _, _, _, _ -> :ok end)
      expect(EmailSenderMock, :send_verification_email, fn _, _ ->
        {:error, :smtp_error}
      end)

      params = %{email: "test@example.com", code_challenge: "challenge"}

      assert {:error, :email_delivery_failed} = OAuth2Flow.initiate(params)
    end

    test "normalizes email to lowercase" do
      challenge = "test_challenge"

      expect(AuthorizationCodeStoreMock, :store, fn _, _, email_obj, _ ->
        assert %EmailAddress{address: "test@example.com"} = email_obj
        :ok
      end)

      expect(EmailSenderMock, :send_verification_email, fn email_obj, _ ->
        assert %EmailAddress{address: "test@example.com"} = email_obj
        {:ok, %{}}
      end)

      params = %{email: "Test@Example.COM", code_challenge: challenge}

      OAuth2Flow.initiate(params)
    end
  end

  describe "exchange_authorization_code/1" do
    test "successfully exchanges code for tokens with valid params" do
      code = "test_code"
      verifier = "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"
      challenge = :crypto.hash(:sha256, verifier) |> Base.url_encode64(padding: false)
      email = "test@example.com"

      expect(AuthorizationCodeStoreMock, :retrieve_and_delete, fn ^code ->
        {:ok, email, challenge}
      end)

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
    end

    test "returns error for invalid authorization code" do
      expect(AuthorizationCodeStoreMock, :retrieve_and_delete, fn _ ->
        {:error, :code_not_found}
      end)

      params = %{code: "invalid_code", code_verifier: "verifier"}

      assert {:error, :invalid_authorization_code} = OAuth2Flow.exchange_authorization_code(params)
    end

    test "returns error for invalid code_verifier" do
      code = "test_code"
      verifier = "correct_verifier"
      challenge = :crypto.hash(:sha256, verifier) |> Base.url_encode64(padding: false)

      expect(AuthorizationCodeStoreMock, :retrieve_and_delete, fn ^code ->
        {:ok, "test@example.com", challenge}
      end)

      params = %{code: code, code_verifier: "wrong_verifier"}

      assert {:error, :invalid_authorization_code} = OAuth2Flow.exchange_authorization_code(params)
    end

    test "returns error when email from store is invalid" do
      code = "test_code"
      verifier = "test_verifier"
      challenge = :crypto.hash(:sha256, verifier) |> Base.url_encode64(padding: false)

      expect(AuthorizationCodeStoreMock, :retrieve_and_delete, fn ^code ->
        {:ok, "not-an-email", challenge}
      end)

      params = %{code: code, code_verifier: verifier}

      assert {:error, :service_unavailable} = OAuth2Flow.exchange_authorization_code(params)
    end

    test "returns error when code store is unavailable" do
      expect(AuthorizationCodeStoreMock, :retrieve_and_delete, fn _ ->
        {:error, :redis_unavailable}
      end)

      params = %{code: "test_code", code_verifier: "verifier"}

      assert {:error, :service_unavailable} = OAuth2Flow.exchange_authorization_code(params)
    end
  end

  describe "refresh_access_token/1" do
    test "successfully refreshes access token with valid refresh token" do
      {:ok, email} = EmailAddress.create("test@example.com")
      {:ok, refresh_token} = Pergamino.Infrastructure.Auth.TokenGenerator.generate_refresh_token(email)

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
    end

    test "returns error for invalid refresh token" do
      assert {:error, :invalid_refresh_token} = OAuth2Flow.refresh_access_token("invalid.token.here")
    end

    test "returns error for expired refresh token" do
      expired_token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjEsImlhdCI6MX0.invalid"

      assert {:error, :invalid_refresh_token} = OAuth2Flow.refresh_access_token(expired_token)
    end
  end
end
