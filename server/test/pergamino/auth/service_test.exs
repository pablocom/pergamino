defmodule Pergamino.Auth.ServiceTest do
  use ExUnit.Case, async: true

  import Swoosh.TestAssertions

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
        assert_no_email_sent()
      end
    end

    test "sends device binding email with valid JWT token" do
      email = "pablocom96@pablo.com"

      assert :ok = Service.create_device_binding_link(email)

      assert_email_sent(fn sent_email ->
        token = extract_token_from_email(sent_email)
        {:ok, claims} = Token.verify(token)

        sent_email.to == [{"", email}] and
          sent_email.from == {"", "noreply@pergamino.dev"} and
          sent_email.subject == "Complete Your Device Setup" and
          String.contains?(sent_email.text_body, "pergamino://bind?token=") and
          claims["email"] == email and
          claims["iss"] == "pergamino" and
          claims["exp"] - claims["iat"] == @ten_minutes_in_seconds
      end)
    end

    defp extract_token_from_email(email) do
      [_, token_part] = String.split(email.text_body, "pergamino://bind?token=")
      String.trim(token_part)
    end
  end
end
