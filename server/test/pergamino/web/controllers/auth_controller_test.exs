defmodule Pergamino.Web.AuthControllerTest do
  use Pergamino.ConnCase

  describe "POST /api/auth/login" do
    test "returns deeplink with hardcoded token", %{conn: conn} do
      conn = post(conn, ~p"/api/auth/login")

      assert json_response(conn, 200) == %{
               "deeplink" => "myapp://verify?token=secret_123"
             }
    end
  end
end
