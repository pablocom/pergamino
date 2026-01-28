defmodule Pergamino.Unit.Web.Validation.ValidatorTest do
  use ExUnit.Case, async: true

  alias Pergamino.Web.Validation.Validator
  alias Pergamino.Web.Errors.ValidationError

  describe "validate/2 with :required validator" do
    test "succeeds when required field is present" do
      params = %{"email" => "test@example.com"}
      schema = [email: [:required]]

      assert {:ok, %{email: "test@example.com"}} = Validator.validate(params, schema)
    end

    test "fails when required field is missing" do
      params = %{}
      schema = [email: [:required]]

      assert {:error, [%ValidationError{field: :email, code: :required}]} =
               Validator.validate(params, schema)
    end

    test "fails when required field is nil" do
      params = %{"email" => nil}
      schema = [email: [:required]]

      assert {:error, [%ValidationError{field: :email, code: :required}]} =
               Validator.validate(params, schema)
    end

    test "fails when required field is empty string" do
      params = %{"email" => ""}
      schema = [email: [:required]]

      assert {:error, [%ValidationError{field: :email, code: :required}]} =
               Validator.validate(params, schema)
    end

    test "fails when required field is whitespace only" do
      params = %{"email" => "   "}
      schema = [email: [:required]]

      assert {:error, [%ValidationError{field: :email, code: :required}]} =
               Validator.validate(params, schema)
    end
  end

  describe "validate/2 with {:type, :string} validator" do
    test "succeeds when field is a string" do
      params = %{"email" => "test@example.com"}
      schema = [email: [{:type, :string}]]

      assert {:ok, %{email: "test@example.com"}} = Validator.validate(params, schema)
    end

    test "fails when field is not a string" do
      params = %{"email" => 123}
      schema = [email: [{:type, :string}]]

      assert {:error, [%ValidationError{field: :email, code: :invalid_format}]} =
               Validator.validate(params, schema)
    end
  end

  describe "validate/2 with {:max_length, n} validator" do
    test "succeeds when string is within max length" do
      params = %{"email" => "test@example.com"}
      schema = [email: [{:max_length, 255}]]

      assert {:ok, %{email: "test@example.com"}} = Validator.validate(params, schema)
    end

    test "succeeds when string equals max length" do
      params = %{"email" => String.duplicate("a", 255)}
      schema = [email: [{:max_length, 255}]]

      assert {:ok, _} = Validator.validate(params, schema)
    end

    test "fails when string exceeds max length" do
      params = %{"email" => String.duplicate("a", 256)}
      schema = [email: [{:max_length, 255}]]

      assert {:error, [%ValidationError{field: :email, code: :too_long, details: %{max_length: 255}}]} =
               Validator.validate(params, schema)
    end
  end

  describe "validate/2 with {:min_length, n} validator" do
    test "succeeds when string meets min length" do
      params = %{"code_verifier" => String.duplicate("a", 43)}
      schema = [code_verifier: [{:min_length, 43}]]

      assert {:ok, %{code_verifier: _}} = Validator.validate(params, schema)
    end

    test "succeeds when string exceeds min length" do
      params = %{"code_verifier" => String.duplicate("a", 50)}
      schema = [code_verifier: [{:min_length, 43}]]

      assert {:ok, _} = Validator.validate(params, schema)
    end

    test "fails when string is below min length" do
      params = %{"code_verifier" => String.duplicate("a", 42)}
      schema = [code_verifier: [{:min_length, 43}]]

      assert {:error,
              [%ValidationError{field: :code_verifier, code: :too_short, details: %{min_length: 43}}]} =
               Validator.validate(params, schema)
    end
  end

  describe "validate/2 with custom validator function" do
    test "succeeds when custom validator returns :ok" do
      params = %{"email" => "test@example.com"}
      custom_validator = fn value -> if String.contains?(value, "@"), do: :ok, else: {:error, :no_at_sign} end
      schema = [email: [custom_validator]]

      assert {:ok, %{email: "test@example.com"}} = Validator.validate(params, schema)
    end

    test "fails when custom validator returns {:error, reason}" do
      params = %{"email" => "invalid"}
      custom_validator = fn value -> if String.contains?(value, "@"), do: :ok, else: {:error, "must contain @"} end
      schema = [email: [custom_validator]]

      assert {:error, [%ValidationError{field: :email, code: :invalid_format, message: "must contain @"}]} =
               Validator.validate(params, schema)
    end
  end

  describe "validate/2 with multiple validators" do
    test "succeeds when all validators pass" do
      params = %{"email" => "test@example.com"}
      schema = [email: [:required, {:type, :string}, {:max_length, 255}]]

      assert {:ok, %{email: "test@example.com"}} = Validator.validate(params, schema)
    end

    test "fails on first validator that fails" do
      params = %{"email" => ""}
      schema = [email: [:required, {:type, :string}, {:max_length, 255}]]

      assert {:error, [%ValidationError{field: :email, code: :required}]} =
               Validator.validate(params, schema)
    end
  end

  describe "validate/2 with multiple fields" do
    test "succeeds when all fields are valid" do
      params = %{"email" => "test@example.com", "code_challenge" => "challenge123"}
      schema = [email: [:required], code_challenge: [:required]]

      assert {:ok, %{email: "test@example.com", code_challenge: "challenge123"}} =
               Validator.validate(params, schema)
    end

    test "returns all validation errors" do
      params = %{}
      schema = [email: [:required], code_challenge: [:required]]

      assert {:error, errors} = Validator.validate(params, schema)
      assert length(errors) == 2
      assert Enum.any?(errors, fn e -> e.field == :email end)
      assert Enum.any?(errors, fn e -> e.field == :code_challenge end)
    end

    test "accumulates errors across multiple fields" do
      params = %{"email" => "", "code_challenge" => ""}
      schema = [email: [:required], code_challenge: [:required]]

      assert {:error, errors} = Validator.validate(params, schema)
      assert length(errors) == 2
    end
  end

  describe "validate/2 with optional fields" do
    test "succeeds when optional field is missing" do
      params = %{"email" => "test@example.com"}
      schema = [email: [:required], optional_field: [{:type, :string}]]

      assert {:ok, validated} = Validator.validate(params, schema)
      assert validated.email == "test@example.com"
      refute Map.has_key?(validated, :optional_field)
    end

    test "validates optional field when present" do
      params = %{"email" => "test@example.com", "optional_field" => 123}
      schema = [email: [:required], optional_field: [{:type, :string}]]

      assert {:error, [%ValidationError{field: :optional_field, code: :invalid_format}]} =
               Validator.validate(params, schema)
    end
  end
end
