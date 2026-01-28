defmodule Pergamino.Unit.Web.Schemas.RefreshTokenRequestTest do
  use ExUnit.Case, async: true

  alias Pergamino.Web.Schemas.RefreshTokenRequest

  describe "validate/1" do
    test "returns ok with valid refresh_token" do
      params = %{"refresh_token" => "valid_refresh_token_string"}

      assert {:ok, validated} = RefreshTokenRequest.validate(params)
      assert validated.refresh_token == "valid_refresh_token_string"
    end

    test "accepts string keys" do
      params = %{"refresh_token" => "token"}

      assert {:ok, _} = RefreshTokenRequest.validate(params)
    end

    test "accepts atom keys" do
      params = %{refresh_token: "token"}

      assert {:ok, _} = RefreshTokenRequest.validate(params)
    end

    test "returns error when refresh_token is missing" do
      params = %{}

      assert {:error, :missing_refresh_token} = RefreshTokenRequest.validate(params)
    end

    test "returns error when refresh_token is empty string" do
      params = %{"refresh_token" => ""}

      assert {:error, :missing_refresh_token} = RefreshTokenRequest.validate(params)
    end

    test "returns error when refresh_token is nil" do
      params = %{"refresh_token" => nil}

      assert {:error, :missing_refresh_token} = RefreshTokenRequest.validate(params)
    end
  end
end
