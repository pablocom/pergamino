defmodule Pergamino.Component.Web.Controllers.TokenTest do
  use Pergamino.ConnCase, async: true

  import RedisHelpers
  import DynamoDBHelpers

  alias Pergamino.Domain.EmailAddress

  alias Pergamino.Infrastructure.Auth.{
    AuthorizationCode,
    AuthorizationCodeStore,
    RefreshToken,
    RefreshTokenStore,
    TokenGenerator
  }

  @pkce_verifier "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"

  setup_all do
    ensure_refresh_tokens_table()
    :ok
  end

  setup do
    on_exit(fn ->
      flush_authorization_codes()
      flush_refresh_tokens()
    end)

    :ok
  end

  describe "POST /api/token" do
    test "exchanges valid authorization code for tokens", %{conn: conn} do
      {:ok, email} = EmailAddress.create("test@example.com")
      challenge = create_challenge(@pkce_verifier)

      {code, expires_at} = AuthorizationCode.generate()
      :ok = AuthorizationCodeStore.store(code, expires_at, email, challenge)

      params = %{
        "code" => code,
        "code_verifier" => @pkce_verifier
      }

      conn = post(conn, ~p"/api/token", params)

      assert %{
               "access_token" => access_token,
               "refresh_token" => refresh_token,
               "token_type" => "Bearer",
               "expires_in" => 900
             } = json_response(conn, 200)

      assert is_binary(access_token)
      assert is_binary(refresh_token)
      assert {:ok, claims} = TokenGenerator.verify(access_token)
      assert claims["email"] == "test@example.com"
      assert claims["typ"] == "access"

      assert {:ok, "test@example.com"} = RefreshTokenStore.retrieve_and_delete(refresh_token)
    end

    test "returns error for invalid authorization code", %{conn: conn} do
      params = %{
        "code" => "invalid_code",
        "code_verifier" => @pkce_verifier
      }

      conn = post(conn, ~p"/api/token", params)

      assert %{"type" => type} = json_response(conn, 400)
      assert type == "https://pergamino.app/errors/invalid-authorization-code"
    end

    test "returns error for invalid code_verifier", %{conn: conn} do
      {:ok, email} = EmailAddress.create("test@example.com")
      challenge = create_challenge(@pkce_verifier)

      {code, expires_at} = AuthorizationCode.generate()
      :ok = AuthorizationCodeStore.store(code, expires_at, email, challenge)

      params = %{
        "code" => code,
        "code_verifier" => "wrong_verifier"
      }

      conn = post(conn, ~p"/api/token", params)

      assert %{"type" => type} = json_response(conn, 400)
      assert type == "https://pergamino.app/errors/invalid-authorization-code"
    end

    test "returns error when code is missing", %{conn: conn} do
      params = %{"code_verifier" => @pkce_verifier}

      conn = post(conn, ~p"/api/token", params)

      assert %{"type" => type} = json_response(conn, 400)
      assert type == "https://pergamino.app/errors/missing-code"
    end

    test "returns error when code_verifier is missing", %{conn: conn} do
      {:ok, email} = EmailAddress.create("test@example.com")
      challenge = create_challenge(@pkce_verifier)

      {code, expires_at} = AuthorizationCode.generate()
      :ok = AuthorizationCodeStore.store(code, expires_at, email, challenge)

      params = %{"code" => code}

      conn = post(conn, ~p"/api/token", params)

      assert %{"type" => type} = json_response(conn, 400)
      assert type == "https://pergamino.app/errors/missing-code-verifier"
    end

    test "authorization code can only be used once", %{conn: conn} do
      {:ok, email} = EmailAddress.create("test@example.com")
      challenge = create_challenge(@pkce_verifier)
      {code, expires_at} = AuthorizationCode.generate()
      :ok = AuthorizationCodeStore.store(code, expires_at, email, challenge)

      params = %{
        "code" => code,
        "code_verifier" => @pkce_verifier
      }

      post(conn, ~p"/api/token", params)
      conn2 = post(conn, ~p"/api/token", params)

      assert %{"type" => type} = json_response(conn2, 400)
      assert type == "https://pergamino.app/errors/invalid-authorization-code"
    end
  end

  describe "POST /api/token/refresh" do
    test "refreshes access token with valid refresh token", %{conn: conn} do
      {:ok, email} = EmailAddress.create("test@example.com")
      {refresh_token, expires_at} = RefreshToken.generate()
      :ok = RefreshTokenStore.store(refresh_token, expires_at, email)

      params = %{"refresh_token" => refresh_token}
      conn = post(conn, ~p"/api/token/refresh", params)

      assert %{
               "access_token" => new_access_token,
               "refresh_token" => new_refresh_token,
               "token_type" => "Bearer",
               "expires_in" => 900
             } = json_response(conn, 200)

      assert is_binary(new_access_token)
      assert is_binary(new_refresh_token)
      assert new_refresh_token != refresh_token

      assert {:ok, claims} = TokenGenerator.verify(new_access_token)
      assert claims["email"] == "test@example.com"

      assert {:ok, "test@example.com"} = RefreshTokenStore.retrieve_and_delete(new_refresh_token)
    end

    test "returns error for invalid refresh token", %{conn: conn} do
      params = %{"refresh_token" => "invalid_token_string"}

      conn = post(conn, ~p"/api/token/refresh", params)

      assert %{"type" => type} = json_response(conn, 400)
      assert type == "https://pergamino.app/errors/invalid-refresh-token"
    end

    test "returns error when refresh_token is missing", %{conn: conn} do
      params = %{}

      conn = post(conn, ~p"/api/token/refresh", params)

      assert %{"type" => type} = json_response(conn, 400)
      assert type == "https://pergamino.app/errors/missing-refresh-token"
    end

    test "old refresh token cannot be reused after rotation", %{conn: conn} do
      {:ok, email} = EmailAddress.create("test@example.com")
      {refresh_token, expires_at} = RefreshToken.generate()
      :ok = RefreshTokenStore.store(refresh_token, expires_at, email)

      params = %{"refresh_token" => refresh_token}
      conn1 = post(conn, ~p"/api/token/refresh", params)

      assert %{
               "access_token" => _access_token,
               "refresh_token" => new_refresh_token
             } = json_response(conn1, 200)

      assert new_refresh_token != refresh_token

      conn2 = post(conn, ~p"/api/token/refresh", params)

      assert %{"type" => type} = json_response(conn2, 400)
      assert type == "https://pergamino.app/errors/invalid-refresh-token"
    end

    test "can chain multiple refresh token rotations", %{conn: conn} do
      {:ok, email} = EmailAddress.create("test@example.com")
      {token1, expires_at1} = RefreshToken.generate()
      :ok = RefreshTokenStore.store(token1, expires_at1, email)

      conn1 = post(conn, ~p"/api/token/refresh", %{"refresh_token" => token1})
      assert %{"refresh_token" => token2} = json_response(conn1, 200)

      conn2 = post(conn, ~p"/api/token/refresh", %{"refresh_token" => token2})
      assert %{"refresh_token" => token3} = json_response(conn2, 200)

      conn3 = post(conn, ~p"/api/token/refresh", %{"refresh_token" => token3})
      assert %{"refresh_token" => _token4} = json_response(conn3, 200)

      assert token1 != token2
      assert token2 != token3
      assert token1 != token3
    end
  end

  defp create_challenge(verifier) do
    :crypto.hash(:sha256, verifier)
    |> Base.url_encode64(padding: false)
  end
end
