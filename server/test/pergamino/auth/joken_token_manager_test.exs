defmodule Pergamino.Auth.JokenTokenManagerTest do
  use ExUnit.Case, async: true

  @one_hour_in_seconds 600

  describe "generates a token using the HS256 algorithm" do
    test "verifies claims and expiration" do
      email = "lucy@vault-tec.com"

      {:ok, token} = Pergamino.Auth.JokenTokenManager.generate(email)

      {:ok, verified_claims} = Pergamino.Auth.JokenTokenManager.verify(token)

      assert verified_claims["email"] == "lucy@vault-tec.com"
      assert verified_claims["exp"] - verified_claims["iat"] == @one_hour_in_seconds
      assert verified_claims["iss"] == "pergamino"
    end
  end
end
