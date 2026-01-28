defmodule Pergamino.Unit.Web.Errors.UnknownErrorTest do
  use ExUnit.Case, async: true

  alias Pergamino.Web.Errors.UnknownError

  describe "internal_server_error/0" do
    test "creates internal server error" do
      error = UnknownError.internal_server_error()

      assert %UnknownError{
               code: :internal_server_error,
               message: "An unexpected error occurred",
               details: %{}
             } = error
    end
  end
end
