defmodule Pergamino.Unit.Web.Schemas.VerificationEmailRequestTest do
  use ExUnit.Case, async: true

  alias Pergamino.Web.Schemas.VerificationEmailRequest

  describe "validate/1" do
    test "returns ok with valid email and code_challenge" do
      params = %{
        "email" => "test@example.com",
        "code_challenge" => "valid_challenge_string"
      }

      assert {:ok, validated} = VerificationEmailRequest.validate(params)
      assert validated.email == "test@example.com"
      assert validated.code_challenge == "valid_challenge_string"
    end

    test "accepts string keys" do
      params = %{
        "email" => "test@example.com",
        "code_challenge" => "challenge"
      }

      assert {:ok, _} = VerificationEmailRequest.validate(params)
    end

    test "accepts atom keys" do
      params = %{
        email: "test@example.com",
        code_challenge: "challenge"
      }

      assert {:ok, _} = VerificationEmailRequest.validate(params)
    end

    test "returns error when email is missing" do
      params = %{"code_challenge" => "challenge"}

      assert {:error, :missing_email} = VerificationEmailRequest.validate(params)
    end

    test "returns error when email is empty string" do
      params = %{
        "email" => "",
        "code_challenge" => "challenge"
      }

      assert {:error, :missing_email} = VerificationEmailRequest.validate(params)
    end

    test "returns error when email is nil" do
      params = %{
        "email" => nil,
        "code_challenge" => "challenge"
      }

      assert {:error, :missing_email} = VerificationEmailRequest.validate(params)
    end

    test "returns error when code_challenge is missing" do
      params = %{"email" => "test@example.com"}

      assert {:error, :missing_code_challenge} = VerificationEmailRequest.validate(params)
    end

    test "returns error when code_challenge is empty string" do
      params = %{
        "email" => "test@example.com",
        "code_challenge" => ""
      }

      assert {:error, :missing_code_challenge} = VerificationEmailRequest.validate(params)
    end

    test "returns error when code_challenge is nil" do
      params = %{
        "email" => "test@example.com",
        "code_challenge" => nil
      }

      assert {:error, :missing_code_challenge} = VerificationEmailRequest.validate(params)
    end

    test "returns error when email format is invalid" do
      params = %{
        "email" => "not-an-email",
        "code_challenge" => "challenge"
      }

      assert {:error, :invalid_email} = VerificationEmailRequest.validate(params)
    end

    test "allows emails with subdomains" do
      params = %{
        "email" => "user@mail.example.com",
        "code_challenge" => "challenge"
      }

      assert {:ok, validated} = VerificationEmailRequest.validate(params)
      assert validated.email == "user@mail.example.com"
    end

    test "allows emails with plus addressing" do
      params = %{
        "email" => "user+tag@example.com",
        "code_challenge" => "challenge"
      }

      assert {:ok, validated} = VerificationEmailRequest.validate(params)
      assert validated.email == "user+tag@example.com"
    end
  end
end
