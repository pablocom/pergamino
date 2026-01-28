defmodule Pergamino.Unit.Web.Schemas.TokenRequestTest do
  use ExUnit.Case, async: true

  alias Pergamino.Web.Schemas.TokenRequest

  describe "validate/1" do
    test "returns ok with valid code and code_verifier" do
      params = %{
        "code" => "valid_authorization_code",
        "code_verifier" => "valid_code_verifier"
      }

      assert {:ok, validated} = TokenRequest.validate(params)
      assert validated.code == "valid_authorization_code"
      assert validated.code_verifier == "valid_code_verifier"
    end

    test "accepts string keys" do
      params = %{
        "code" => "auth_code",
        "code_verifier" => "verifier"
      }

      assert {:ok, _} = TokenRequest.validate(params)
    end

    test "accepts atom keys" do
      params = %{
        code: "auth_code",
        code_verifier: "verifier"
      }

      assert {:ok, _} = TokenRequest.validate(params)
    end

    test "returns error when code is missing" do
      params = %{"code_verifier" => "verifier"}

      assert {:error, :missing_code} = TokenRequest.validate(params)
    end

    test "returns error when code is empty string" do
      params = %{
        "code" => "",
        "code_verifier" => "verifier"
      }

      assert {:error, :missing_code} = TokenRequest.validate(params)
    end

    test "returns error when code is nil" do
      params = %{
        "code" => nil,
        "code_verifier" => "verifier"
      }

      assert {:error, :missing_code} = TokenRequest.validate(params)
    end

    test "returns error when code_verifier is missing" do
      params = %{"code" => "auth_code"}

      assert {:error, :missing_code_verifier} = TokenRequest.validate(params)
    end

    test "returns error when code_verifier is empty string" do
      params = %{
        "code" => "auth_code",
        "code_verifier" => ""
      }

      assert {:error, :missing_code_verifier} = TokenRequest.validate(params)
    end

    test "returns error when code_verifier is nil" do
      params = %{
        "code" => "auth_code",
        "code_verifier" => nil
      }

      assert {:error, :missing_code_verifier} = TokenRequest.validate(params)
    end
  end
end
