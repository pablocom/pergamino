defmodule Pergamino.Web.Controllers.AuthTest do
  use Pergamino.ConnCase

  import Swoosh.TestAssertions

  describe "POST /api/auth/device-binding-link" do
    test "sends email and returns 202 for valid email", %{conn: conn} do
      conn = post(conn, ~p"/api/auth/device-binding-link", %{"email" => "test@example.com"})

      assert conn.status == 202
      assert conn.resp_body == ""

      assert_email_sent(fn sent_email ->
        [_, token_part] = String.split(sent_email.text_body, "pergamino://bind?token=")
        token = String.trim(token_part)
        {:ok, claims} = Pergamino.Auth.Token.verify(token)

        sent_email.to == [{"", "test@example.com"}] and
          sent_email.subject == "Complete Your Device Setup" and
          String.contains?(sent_email.text_body, "pergamino://bind?token=") and
          claims["email"] == "test@example.com"
      end)
    end

    test "returns Problem Details when email parameter is missing", %{conn: conn} do
      conn = post(conn, ~p"/api/auth/device-binding-link", %{})

      assert_validation_error(
        conn,
        "Email parameter is required",
        "/api/auth/device-binding-link"
      )

      assert_no_email_sent()
    end

    test "returns Problem Details when email format is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/auth/device-binding-link", %{"email" => "not-an-email"})

      assert_validation_error(conn, "Email format is invalid", "/api/auth/device-binding-link")
      assert_no_email_sent()
    end
  end
end
