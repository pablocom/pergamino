defmodule Pergamino.Web.Controllers.VerificationEmailTest do
  use Pergamino.ConnCase

  import Swoosh.TestAssertions

  describe "POST /api/verification-emails" do
    test "sends email and returns 202", %{conn: conn} do
      conn = post(conn, ~p"/api/verification-emails", %{"email" => "test@example.com"})

      assert conn.status == 202
      assert conn.resp_body == ""

      assert_email_sent(fn sent_email ->
        [_, token_part] = String.split(sent_email.text_body, "pergamino://bind?token=")
        token = String.trim(token_part)
        {:ok, claims} = Pergamino.Infrastructure.Auth.TokenGenerator.verify(token)

        sent_email.to == [{"", "test@example.com"}] and
          sent_email.subject == "Complete Your Device Setup" and
          String.contains?(sent_email.text_body, "pergamino://bind?token=") and
          claims["email"] == "test@example.com"
      end)
    end

    test "returns an error when email parameter is missing", %{conn: conn} do
      conn = post(conn, ~p"/api/verification-emails", %{})

      assert_validation_error(
        conn,
        "Email parameter is required",
        "/api/verification-emails"
      )

      assert_no_email_sent()
    end

    test "returns an error when email format is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/verification-emails", %{"email" => "not-an-email"})

      assert_validation_error(conn, "Email format is invalid", "/api/verification-emails")
      assert_no_email_sent()
    end
  end
end
