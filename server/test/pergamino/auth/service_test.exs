defmodule Pergamino.Auth.ServiceTest do
  use ExUnit.Case, async: true

  alias Pergamino.Auth.Service
  alias Pergamino.Auth.Token

  @ten_minutes_in_seconds 600

  @invalid_email_scenarios [
    {"plainaddress", "missing @ symbol"},
    {"@example.com", "missing local part"},
    {"joe.smith@.com", "domain starts with dot"},
    {"joe.smith@", "missing domain"},
    {"email@example.com (Joe Smith)", "contains comment/parentheses"},
    {"email@example .com", "contains spaces in domain"},
    {"user name@example.com", "contains spaces in local part"},
    {"user+name@exam_ple.com", "domain contains underscore"},
    {"", "is empty string"},
    {nil, "is nil"},
    {String.duplicate("a", 255) <> "@example.com", "exceeds 255 chars"}
  ]

  describe "create_device_binding_link/1" do
    for {email_input, reason} <- @invalid_email_scenarios do
      test "refuses to create device binding link when email #{reason}" do
        email = unquote(email_input)

        assert {:error, :invalid_email} = Service.create_device_binding_link(email)
      end
    end

    test "returns a device binding deeplink with a token containing the user email" do
      email = "pablocom96@pablo.com"

      {:ok, deeplink} = Service.create_device_binding_link(email)

      assert String.starts_with?(deeplink, "pergamino://bind?token=")

      {:ok, claims} = Token.verify(get_token_from_deeplink(deeplink))

      assert claims["email"] == email
      assert claims["iss"] == "pergamino"
      assert claims["exp"] - claims["iat"] == @ten_minutes_in_seconds
    end

    defp get_token_from_deeplink(deeplink) do
      uri = URI.parse(deeplink)
      query_params = URI.decode_query(uri.query)
      Map.get(query_params, "token")
    end
  end
end
