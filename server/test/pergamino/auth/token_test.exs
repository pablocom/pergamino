defmodule Pergamino.Auth.TokenTest do
  use ExUnit.Case, async: true

  alias Pergamino.Auth.Token
  alias Pergamino.Domain.Email

  @ten_minutes_in_seconds 600

  describe "generate/1" do
    test "token contains the email in claims" do
      {:ok, email} = Email.create("test@example.com")

      {:ok, jwt_token} = Token.generate(email)
      {:ok, claims} = Token.verify(jwt_token)

      assert claims["email"] == email.address
      assert claims["iss"] == "pergamino"
      assert claims["exp"] - claims["iat"] == @ten_minutes_in_seconds
    end

    test "returns error for invalid token" do
      assert {:error, :signature_error} = Token.verify("invalid.token.here")
    end
  end
end
