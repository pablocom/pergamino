defmodule PergaminoWeb.AuthControllerTest do
  use PergaminoWeb.ConnCase

  describe "POST /api/auth/login" do
    test "returns deeplink with hardcoded token", %{conn: conn} do
      conn = post(conn, ~p"/api/auth/login")

      assert json_response(conn, 200) == %{
               "deeplink" => "myapp://verify?token=secret_123"
             }
    end

    test "returns 200 status code", %{conn: conn} do
      conn = post(conn, ~p"/api/auth/login")

      assert conn.status == 200
    end

    test "returns JSON content type", %{conn: conn} do
      conn = post(conn, ~p"/api/auth/login")

      assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]
    end
  end
end
