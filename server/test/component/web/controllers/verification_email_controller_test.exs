defmodule Component.Web.Controllers.VerificationEmailTest do
  use Pergamino.ConnCase

  import Swoosh.TestAssertions

  @pkce_verifier "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"

  describe "POST /api/verification-emails" do
    test "sends email and returns 202", %{conn: conn} do
      challenge = create_challenge(@pkce_verifier)

      params = %{
        "email" => "test@example.com",
        "code_challenge" => challenge
      }

      conn = post(conn, ~p"/api/verification-emails", params)

      assert conn.status == 202
      assert conn.resp_body == ""

      assert_email_sent(fn sent_email ->
        sent_email.to == [{"", "test@example.com"}] and
          sent_email.subject == "Complete Your Device Setup" and
          String.contains?(sent_email.text_body, "pergamino://bind?code=")
      end)
    end

    test "returns an error when email parameter is missing", %{conn: conn} do
      challenge = create_challenge(@pkce_verifier)

      params = %{
        "code_challenge" => challenge
      }

      conn = post(conn, ~p"/api/verification-emails", params)

      assert %{
               "type" => "https://pergamino.app/errors/missing-email",
               "detail" => "Email parameter is required",
               "status" => 400
             } = json_response(conn, 400)

      assert_no_email_sent()
    end

    test "returns an error when code_challenge is missing", %{conn: conn} do
      params = %{
        "email" => "test@example.com"
      }

      conn = post(conn, ~p"/api/verification-emails", params)

      assert %{
               "type" => "https://pergamino.app/errors/missing-code-challenge",
               "detail" => "Code challenge parameter is required",
               "status" => 400
             } = json_response(conn, 400)

      assert_no_email_sent()
    end

    test "returns an error when email format is invalid", %{conn: conn} do
      challenge = create_challenge(@pkce_verifier)

      params = %{
        "email" => "not-an-email",
        "code_challenge" => challenge
      }

      conn = post(conn, ~p"/api/verification-emails", params)

      assert %{
               "type" => "https://pergamino.app/errors/invalid-email-format",
               "detail" => "Email format is invalid",
               "status" => 400
             } = json_response(conn, 400)

      assert_no_email_sent()
    end
  end

  defp create_challenge(verifier) do
    :crypto.hash(:sha256, verifier)
    |> Base.url_encode64(padding: false)
  end
end
