defmodule Pergamino.Infrastructure.Auth.TokenGeneratorTest do
  use ExUnit.Case, async: true

  alias Pergamino.Domain.EmailAddress
  alias Pergamino.Infrastructure.Auth.TokenGenerator

  @access_token_expiration_seconds 900
  @refresh_token_expiration_seconds 7_776_000

  describe "generate/1" do
    test "generates valid JWT token for email value object" do
      {:ok, email} = EmailAddress.create("test@example.com")

      assert {:ok, token} = TokenGenerator.generate(email)
      assert is_binary(token)
      assert String.length(token) > 0
    end

    test "generated token can be verified and contains correct claims" do
      {:ok, email} = EmailAddress.create("test@example.com")
      {:ok, token} = TokenGenerator.generate(email)

      assert {:ok, claims} = TokenGenerator.verify(token)
      assert claims["email"] == "test@example.com"
      assert claims["iss"] == "pergamino"
      assert claims["aud"] == "pergamino"
      assert claims["exp"] - claims["iat"] == @access_token_expiration_seconds
    end

    test "generates different tokens for same email" do
      {:ok, email} = EmailAddress.create("test@example.com")

      {:ok, token1} = TokenGenerator.generate(email)
      {:ok, token2} = TokenGenerator.generate(email)

      assert token1 != token2
    end
  end

  describe "verify/1" do
    test "returns error for invalid token" do
      assert {:error, _reason} = TokenGenerator.verify("invalid.token.here")
    end

    test "returns error for expired token" do
      invalid_token =
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjEsImlhdCI6MX0.invalid"

      assert {:error, _reason} = TokenGenerator.verify(invalid_token)
    end
  end

  describe "generate_refresh_token/1" do
    test "generates valid JWT refresh token for email value object" do
      {:ok, email} = EmailAddress.create("test@example.com")

      assert {:ok, token} = TokenGenerator.generate_refresh_token(email)
      assert is_binary(token)
      assert String.length(token) > 0
    end

    test "generated refresh token can be verified and contains correct claims" do
      {:ok, email} = EmailAddress.create("test@example.com")
      {:ok, token} = TokenGenerator.generate_refresh_token(email)

      assert {:ok, claims} = TokenGenerator.verify_refresh_token(token)
      assert claims["email"] == "test@example.com"
      assert claims["iss"] == "pergamino"
      assert claims["aud"] == "pergamino"
      assert claims["typ"] == "refresh"
      assert is_binary(claims["jti"])
      assert claims["exp"] - claims["iat"] == @refresh_token_expiration_seconds
    end

    test "generates different tokens and jti for same email" do
      {:ok, email} = EmailAddress.create("test@example.com")

      {:ok, token1} = TokenGenerator.generate_refresh_token(email)
      {:ok, token2} = TokenGenerator.generate_refresh_token(email)
      {:ok, claims1} = TokenGenerator.verify_refresh_token(token1)
      {:ok, claims2} = TokenGenerator.verify_refresh_token(token2)

      assert token1 != token2
      assert is_binary(claims1["jti"])
      assert is_binary(claims2["jti"])
      assert claims1["jti"] != claims2["jti"]
    end
  end

  describe "verify_refresh_token/1" do
    test "returns error for invalid token" do
      assert {:error, _reason} = TokenGenerator.verify_refresh_token("invalid.token.here")
    end

    test "returns error for expired token" do
      invalid_token =
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjEsImlhdCI6MX0.invalid"

      assert {:error, _reason} = TokenGenerator.verify_refresh_token(invalid_token)
    end

    test "returns error for access token used as refresh token" do
      {:ok, email} = EmailAddress.create("test@example.com")
      {:ok, access_token} = TokenGenerator.generate(email)

      assert {:error, _reason} = TokenGenerator.verify_refresh_token(access_token)
    end
  end
end
