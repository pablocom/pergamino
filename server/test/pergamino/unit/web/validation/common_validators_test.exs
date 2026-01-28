defmodule Pergamino.Unit.Web.Validation.CommonValidatorsTest do
  use ExUnit.Case, async: true

  alias Pergamino.Web.Validation.CommonValidators

  describe "email_format/0" do
    test "returns validator function" do
      validator = CommonValidators.email_format()
      assert is_function(validator, 1)
    end

    test "accepts valid email addresses" do
      validator = CommonValidators.email_format()

      valid_emails = [
        "test@example.com",
        "user.name@example.com",
        "user+tag@example.co.uk",
        "123@example.com",
        "a@b.c"
      ]

      for email <- valid_emails do
        assert :ok = validator.(email), "Expected #{email} to be valid"
      end
    end

    test "rejects invalid email addresses" do
      validator = CommonValidators.email_format()

      invalid_emails = [
        "invalid",
        "@example.com",
        "user@",
        "user @example.com",
        "user@example",
        ""
      ]

      for email <- invalid_emails do
        assert {:error, _} = validator.(email), "Expected #{email} to be invalid"
      end
    end
  end

  describe "pkce_verifier_format/0" do
    test "returns validator function" do
      validator = CommonValidators.pkce_verifier_format()
      assert is_function(validator, 1)
    end

    test "accepts valid PKCE verifiers" do
      validator = CommonValidators.pkce_verifier_format()

      valid_verifiers = [
        String.duplicate("a", 43),
        String.duplicate("A", 43),
        String.duplicate("0", 43),
        String.duplicate("-", 43),
        String.duplicate("_", 43),
        "abcABC123-_" <> String.duplicate("x", 32),
        String.duplicate("a", 128)
      ]

      for verifier <- valid_verifiers do
        assert :ok = validator.(verifier),
               "Expected verifier of length #{byte_size(verifier)} to be valid"
      end
    end

    test "rejects verifiers that are too short" do
      validator = CommonValidators.pkce_verifier_format()
      short_verifier = String.duplicate("a", 42)

      assert {:error, message} = validator.(short_verifier)
      assert message =~ "43"
    end

    test "rejects verifiers that are too long" do
      validator = CommonValidators.pkce_verifier_format()
      long_verifier = String.duplicate("a", 129)

      assert {:error, message} = validator.(long_verifier)
      assert message =~ "128"
    end

    test "rejects verifiers with invalid characters" do
      validator = CommonValidators.pkce_verifier_format()

      invalid_verifiers = [
        String.duplicate("a", 42) <> "!",
        String.duplicate("a", 42) <> " ",
        String.duplicate("a", 42) <> "+",
        String.duplicate("a", 42) <> "/"
      ]

      for verifier <- invalid_verifiers do
        assert {:error, message} = validator.(verifier)
        assert message =~ "URL-safe"
      end
    end

    test "rejects verifiers with padding" do
      validator = CommonValidators.pkce_verifier_format()
      verifier_with_padding = String.duplicate("a", 42) <> "="

      assert {:error, message} = validator.(verifier_with_padding)
      assert message =~ "URL-safe"
    end
  end
end
