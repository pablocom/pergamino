defmodule Pergamino.Application.VerificationEmailTest do
  use ExUnit.Case, async: false

  import Swoosh.TestAssertions

  alias Pergamino.Application.VerificationEmail
  alias Pergamino.Infrastructure.Auth.TokenGenerator

  describe "send/1" do
    test "sends verification email with deeplink containing valid token" do
      email_string = "test@example.com"

      assert :ok = VerificationEmail.send(email_string)

      assert_email_sent(fn sent_email ->
        [_, token_part] = String.split(sent_email.text_body, "pergamino://bind?token=")
        token = String.trim(token_part)
        {:ok, claims} = TokenGenerator.verify(token)

        sent_email.to == [{"", email_string}] and
          sent_email.from == {"", "noreply@pergamino.dev"} and
          sent_email.subject == "Complete Your Device Setup" and
          claims["email"] == email_string
      end)
    end

    test "returns error for invalid email format" do
      assert {:error, :invalid_email} = VerificationEmail.send("not-an-email")
      assert_no_email_sent()
    end

    test "returns error for empty email" do
      assert {:error, :invalid_email} = VerificationEmail.send("")
      assert_no_email_sent()
    end

    test "normalizes email to lowercase before sending" do
      VerificationEmail.send("Test@Example.COM")

      assert_email_sent(fn sent_email ->
        sent_email.to == [{"", "test@example.com"}]
      end)
    end
  end
end
