defmodule Pergamino.Auth.ServiceTest do
  use ExUnit.Case, async: true

  alias Pergamino.Auth.Service

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

  describe "create_login_link/1" do
    for {email_input, reason} <- @invalid_email_scenarios do
      test "refuses to create link when email #{reason}" do
        email = unquote(email_input)

        assert {:error, :invalid_email} = Service.create_login_link(email)
      end
    end
  end
end
