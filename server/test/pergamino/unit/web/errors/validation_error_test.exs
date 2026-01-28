defmodule Pergamino.Unit.Web.Errors.ValidationErrorTest do
  use ExUnit.Case, async: true

  alias Pergamino.Web.Errors.ValidationError

  describe "required/1" do
    test "creates error for required field" do
      error = ValidationError.required(:email)

      assert %ValidationError{
               field: :email,
               code: :required,
               message: "Email is required",
               details: %{}
             } = error
    end

    test "creates error for code_challenge field" do
      error = ValidationError.required(:code_challenge)

      assert %ValidationError{
               field: :code_challenge,
               code: :required,
               message: "Code Challenge is required"
             } = error
    end
  end

  describe "invalid_format/2" do
    test "creates error with custom message" do
      error = ValidationError.invalid_format(:email, "must be a valid email address")

      assert %ValidationError{
               field: :email,
               code: :invalid_format,
               message: "must be a valid email address",
               details: %{}
             } = error
    end
  end

  describe "too_long/2" do
    test "creates error with max length constraint" do
      error = ValidationError.too_long(:email, 255)

      assert %ValidationError{
               field: :email,
               code: :too_long,
               message: "Email must not exceed 255 characters",
               details: %{max_length: 255}
             } = error
    end
  end

  describe "too_short/2" do
    test "creates error with min length constraint" do
      error = ValidationError.too_short(:code_verifier, 43)

      assert %ValidationError{
               field: :code_verifier,
               code: :too_short,
               message: "Code Verifier must be at least 43 characters",
               details: %{min_length: 43}
             } = error
    end
  end
end
