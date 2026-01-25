defmodule Pergamino.Web.Controllers.TokenTest do
  use Pergamino.ConnCase, async: true

  alias Pergamino.Domain.EmailAddress

  alias Pergamino.Infrastructure.Auth.{
    AuthorizationCodeGenerator,
    AuthorizationCodeStore,
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

  describe "POST /api/token" do
    test "exchanges valid authorization code for tokens", %{
      conn: conn,
      code: code,
      verifier: verifier
    } do
      params = %{
        "code" => code,
        "code_verifier" => verifier
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
      assert {:ok, refresh_claims} = TokenGenerator.verify_refresh_token(refresh_token)
      assert refresh_claims["email"] == "test@example.com"
      assert refresh_claims["typ"] == "refresh"
    end

    test "returns error for invalid authorization code", %{conn: conn, verifier: verifier} do
      params = %{
        "code" => "invalid_code",
        "code_verifier" => verifier
      }

      conn = post(conn, ~p"/api/token", params)

      assert %{"type" => type} = json_response(conn, 400)
      assert type == "https://pergamino.app/errors/invalid-authorization-code"
    end

    test "returns error for invalid code_verifier", %{conn: conn, code: code} do
      params = %{
        "code" => code,
        "code_verifier" => "wrong_verifier"
      }

      conn = post(conn, ~p"/api/token", params)

      assert %{"type" => type} = json_response(conn, 400)
      assert type == "https://pergamino.app/errors/invalid-authorization-code"
    end

    test "returns error when code is missing", %{conn: conn, verifier: verifier} do
      params = %{"code_verifier" => verifier}

      conn = post(conn, ~p"/api/token", params)

      assert %{"type" => type} = json_response(conn, 400)
      assert type == "https://pergamino.app/errors/missing-code"
    end

    test "returns error when code_verifier is missing", %{conn: conn, code: code} do
      params = %{"code" => code}

      conn = post(conn, ~p"/api/token", params)

      assert %{"type" => type} = json_response(conn, 400)
      assert type == "https://pergamino.app/errors/missing-code-verifier"
    end

    test "authorization code can only be used once", %{
      conn: conn,
      code: code,
      verifier: verifier
    } do
      params = %{
        "code" => code,
        "code_verifier" => verifier
      }

      post(conn, ~p"/api/token", params)
      conn2 = post(conn, ~p"/api/token", params)

      assert %{"type" => type} = json_response(conn2, 400)
      assert type == "https://pergamino.app/errors/invalid-authorization-code"
    end
  end

  describe "POST /api/token/refresh" do
    test "refreshes access token with valid refresh token", %{conn: conn, email: email} do
      {:ok, refresh_token} = TokenGenerator.generate_refresh_token(email)

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
      assert {:ok, refresh_claims} = TokenGenerator.verify_refresh_token(new_refresh_token)
      assert refresh_claims["email"] == "test@example.com"
    end

    test "returns error for invalid refresh token", %{conn: conn} do
      params = %{"refresh_token" => "invalid.token.here"}

      conn = post(conn, ~p"/api/token/refresh", params)

      assert %{"type" => type} = json_response(conn, 400)
      assert type == "https://pergamino.app/errors/invalid-refresh-token"
    end

    test "returns error for expired refresh token", %{conn: conn} do
      expired_token =
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjEsImlhdCI6MX0.invalid"

      params = %{"refresh_token" => expired_token}

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

    test "returns error when access token is used instead of refresh token", %{
      conn: conn,
      email: email
    } do
      {:ok, access_token} = TokenGenerator.generate(email)

      params = %{"refresh_token" => access_token}
      conn = post(conn, ~p"/api/token/refresh", params)

      assert %{"type" => type} = json_response(conn, 400)
      assert type == "https://pergamino.app/errors/invalid-refresh-token"
    end
  end
end
