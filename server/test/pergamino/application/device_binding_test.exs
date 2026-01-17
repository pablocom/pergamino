defmodule Pergamino.Application.DeviceBindingTest do
  use ExUnit.Case, async: true

  import Swoosh.TestAssertions

  alias Pergamino.Application.DeviceBinding
  alias Pergamino.Infrastructure.Auth.TokenGenerator
  alias Pergamino.Domain.EmailAddress

  describe "send_binding_link/2" do
    test "sends device binding email with deeplink containing token" do
      email_string = "test@example.com"
      {:ok, email} = EmailAddress.create(email_string)
      {:ok, token} = TokenGenerator.generate(email)

      assert :ok = DeviceBinding.send_binding_link(email_string, token)

      expected_deeplink = "pergamino://bind?token=#{token}"

      assert_email_sent(fn sent_email ->
        sent_email.to == [{"", email_string}] and
          sent_email.from == {"", "noreply@pergamino.dev"} and
          sent_email.subject == "Complete Your Device Setup" and
          String.contains?(sent_email.text_body, expected_deeplink)
      end)
    end

    test "returns error for invalid email format" do
      invalid_email = "not-an-email"
      token = "some.jwt.token"

      assert {:error, :invalid_email} = DeviceBinding.send_binding_link(invalid_email, token)
      assert_no_email_sent()
    end

    test "returns error for empty email" do
      assert {:error, :invalid_email} = DeviceBinding.send_binding_link("", "token")
      assert_no_email_sent()
    end

    test "normalizes email to lowercase before sending" do
      email_string = "Test@Example.COM"
      {:ok, email} = EmailAddress.create(email_string)
      {:ok, token} = TokenGenerator.generate(email)

      DeviceBinding.send_binding_link(email_string, token)

      assert_email_sent(fn sent_email ->
        sent_email.to == [{"", "test@example.com"}]
      end)
    end
  end
end
