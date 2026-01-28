defmodule Pergamino.Unit.Web.ErrorHandlerTest do
  use Pergamino.ConnCase, async: true

  alias Pergamino.Web.ErrorHandler
  alias Pergamino.Web.Errors.ValidationError
  alias Pergamino.Web.Errors.AuthenticationError
  alias Pergamino.Web.Errors.InfrastructureError
  alias Pergamino.Web.Errors.UnknownError

  describe "call/2 with structured errors" do
    test "handles single ValidationError", %{conn: conn} do
      error = ValidationError.required(:email)

      conn = ErrorHandler.call(conn, {:error, error})

      assert conn.status == 400
      assert %{"type" => type, "detail" => detail, "extensions" => extensions} = json_response(conn, 400)
      assert type == "https://pergamino.app/errors/validation/required-email"
      assert detail == "Email is required"
      assert extensions["field"] == "email"
      assert extensions["code"] == "required"
    end

    test "handles multiple ValidationErrors", %{conn: conn} do
      errors = [
        ValidationError.required(:email),
        ValidationError.required(:code_challenge)
      ]

      conn = ErrorHandler.call(conn, {:error, errors})

      assert conn.status == 400
      assert %{"type" => type, "detail" => detail, "extensions" => extensions} = json_response(conn, 400)
      assert type == "https://pergamino.app/errors/validation"
      assert detail == "Request validation failed"
      assert length(extensions["errors"]) == 2

      error_fields = Enum.map(extensions["errors"], & &1["field"])
      assert "email" in error_fields
      assert "code_challenge" in error_fields
    end

    test "handles AuthenticationError with 401 status", %{conn: conn} do
      error = AuthenticationError.invalid_authorization_code()

      conn = ErrorHandler.call(conn, {:error, error})

      assert conn.status == 401
      assert %{"type" => type, "detail" => detail} = json_response(conn, 401)
      assert type == "https://pergamino.app/errors/authentication/invalid_authorization_code"
      assert detail == "Invalid or expired authorization code"
    end

    test "handles InfrastructureError with 503 status", %{conn: conn} do
      error = InfrastructureError.service_unavailable(:redis)

      conn = ErrorHandler.call(conn, {:error, error})

      assert conn.status == 503
      assert %{"type" => type, "detail" => detail, "extensions" => extensions} = json_response(conn, 503)
      assert type == "https://pergamino.app/errors/service-unavailable"
      assert detail == "Service temporarily unavailable"
      assert extensions["code"] == "service_unavailable"
      refute Map.has_key?(extensions, "service")
    end

    test "handles UnknownError with 500 status", %{conn: conn} do
      error = UnknownError.internal_server_error()

      conn = ErrorHandler.call(conn, {:error, error})

      assert conn.status == 500
      assert %{"type" => type, "detail" => detail} = json_response(conn, 500)
      assert type == "https://pergamino.app/errors/internal-server-error"
      assert detail == "An unexpected error occurred"
    end
  end

  describe "call/2 with unexpected errors" do
    test "handles unexpected error format", %{conn: conn} do
      conn = ErrorHandler.call(conn, {:unexpected, "something"})

      assert conn.status == 500
      assert %{"type" => type, "detail" => detail} = json_response(conn, 500)
      assert type == "https://pergamino.app/errors/internal-server-error"
      assert detail == "An unexpected error occurred"
    end

    test "handles bare error tuple", %{conn: conn} do
      conn = ErrorHandler.call(conn, :some_error)

      assert conn.status == 500
      assert %{"detail" => detail} = json_response(conn, 500)
      assert detail == "An unexpected error occurred"
    end
  end
end
