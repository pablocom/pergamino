defmodule Pergamino.Unit.Web.Errors.AuthenticationErrorTest do
  use ExUnit.Case, async: true

  alias Pergamino.Web.Errors.AuthenticationError

  describe "invalid_authorization_code/0" do
    test "creates authentication error for invalid authorization code" do
      error = AuthenticationError.invalid_authorization_code()

      assert %AuthenticationError{
               code: :invalid_authorization_code,
               message: "Invalid or expired authorization code",
               details: %{}
             } = error
    end
  end

  describe "invalid_refresh_token/0" do
    test "creates authentication error for invalid refresh token" do
      error = AuthenticationError.invalid_refresh_token()

      assert %AuthenticationError{
               code: :invalid_refresh_token,
               message: "Invalid or expired refresh token",
               details: %{}
             } = error
    end
  end
end
