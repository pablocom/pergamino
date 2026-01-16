defmodule Pergamino.Web.Controllers.AuthTest do
  use Pergamino.ConnCase

  describe "POST /api/auth/device-binding-link" do
    test "returns deeplink with JWT token for valid email", %{conn: conn} do
      conn = post(conn, ~p"/api/auth/device-binding-link", %{"email" => "test@example.com"})

      assert %{"deeplink" => deeplink} = json_response(conn, 200)
      assert String.starts_with?(deeplink, "pergamino://bind?token=")

      token = String.replace_prefix(deeplink, "pergamino://bind?token=", "")
      assert {:ok, claims} = Pergamino.Auth.Token.verify(token)
      assert claims["email"] == "test@example.com"
    end

    test "returns Problem Details when email parameter is missing", %{conn: conn} do
      conn = post(conn, ~p"/api/auth/device-binding-link", %{})

      assert json_response(conn, 400) == %{
               "type" => "https://pergamino.dev/problems/validation-error",
               "title" => "Validation Error",
               "status" => 400,
               "detail" => "Email parameter is required",
               "instance" => "/api/auth/device-binding-link",
               "extensions" => %{
                 "error_code" => "INVALID_EMAIL"
               }
             }
    end

    test "returns Problem Details when email format is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/auth/device-binding-link", %{"email" => "not-an-email"})

      assert json_response(conn, 400) == %{
               "type" => "https://pergamino.dev/problems/validation-error",
               "title" => "Validation Error",
               "status" => 400,
               "detail" => "Email format is invalid",
               "instance" => "/api/auth/device-binding-link",
               "extensions" => %{
                 "error_code" => "INVALID_EMAIL"
               }
             }
    end
  end
end
