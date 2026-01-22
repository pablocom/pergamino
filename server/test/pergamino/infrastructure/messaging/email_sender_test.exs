defmodule Pergamino.Infrastructure.Messaging.EmailSenderTest do
  use ExUnit.Case, async: true

  import Swoosh.TestAssertions

  alias Pergamino.Domain.EmailAddress
  alias Pergamino.Infrastructure.Messaging.EmailSender

  describe "send_verification_email/2" do
    test "sends email with deeplink to recipient" do
      {:ok, email} = EmailAddress.create("test@example.com")
      deeplink = "pergamino://bind?token=abc123"

      assert {:ok, _metadata} = EmailSender.send_verification_email(email, deeplink)

      assert_email_sent(fn sent_email ->
        sent_email.to == [{"", "test@example.com"}] and
          sent_email.from == {"", "noreply@pergamino.dev"} and
          sent_email.subject == "Complete Your Device Setup" and
          String.contains?(sent_email.text_body, deeplink)
      end)
    end

    test "email body contains instructions and deeplink" do
      {:ok, email} = EmailAddress.create("user@domain.com")
      deeplink = "pergamino://bind?token=xyz789"

      EmailSender.send_verification_email(email, deeplink)

      assert_email_sent(fn sent_email ->
        String.contains?(sent_email.text_body, "Click the link below") and
          String.contains?(sent_email.text_body, deeplink)
      end)
    end

    test "normalizes email address to lowercase" do
      {:ok, email} = EmailAddress.create("Test@Example.COM")
      deeplink = "pergamino://bind?token=token123"

      EmailSender.send_verification_email(email, deeplink)

      assert_email_sent(fn sent_email ->
        sent_email.to == [{"", "test@example.com"}]
      end)
    end
  end
end
