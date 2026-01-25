defmodule Pergamino.Infrastructure.Auth.AuthorizationCodeStoreTest do
  use ExUnit.Case, async: false

  alias Pergamino.Domain.EmailAddress
  alias Pergamino.Infrastructure.Auth.{AuthorizationCodeGenerator, AuthorizationCodeStore}

  setup do
    {:ok, email} = EmailAddress.create("test@example.com")
    {code, expires_at} = AuthorizationCodeGenerator.generate()
    challenge = "test_challenge_string"

    %{
      email: email,
      code: code,
      expires_at: expires_at,
      challenge: challenge
    }
  end

  describe "store/4" do
    test "stores authorization code with correct TTL", %{
      code: code,
      expires_at: expires_at,
      email: email,
      challenge: challenge
    } do
      assert :ok = AuthorizationCodeStore.store(code, expires_at, email, challenge)

      key = "auth_code:#{code}"
      {:ok, stored_value} = Redix.command(:redix, ["GET", key])
      {:ok, ttl} = Redix.command(:redix, ["TTL", key])

      assert is_binary(stored_value)
      assert ttl > 0
      assert ttl <= 300

      {:ok, decoded} = Jason.decode(stored_value)
      assert decoded["email"] == "test@example.com"
      assert decoded["code_challenge"] == challenge
      refute Map.has_key?(decoded, "code_challenge_method")
    end

    test "stores and retrieves correctly", %{
      code: code,
      expires_at: expires_at,
      email: email,
      challenge: challenge
    } do
      assert :ok = AuthorizationCodeStore.store(code, expires_at, email, challenge)

      {:ok, email_str, stored_challenge} = AuthorizationCodeStore.retrieve_and_delete(code)

      assert email_str == "test@example.com"
      assert stored_challenge == challenge
    end
  end

  describe "retrieve_and_delete/1" do
    test "atomically retrieves and deletes code", %{
      code: code,
      expires_at: expires_at,
      email: email,
      challenge: challenge
    } do
      :ok = AuthorizationCodeStore.store(code, expires_at, email, challenge)

      assert {:ok, "test@example.com", ^challenge} =
               AuthorizationCodeStore.retrieve_and_delete(code)

      assert {:error, :code_not_found} = AuthorizationCodeStore.retrieve_and_delete(code)
    end

    test "returns error for non-existent code" do
      assert {:error, :code_not_found} =
               AuthorizationCodeStore.retrieve_and_delete("nonexistent_code")
    end

    test "returns error for expired code after TTL" do
      {code, _expires_at} = AuthorizationCodeGenerator.generate()
      {:ok, email} = EmailAddress.create("test@example.com")

      short_expires_at = DateTime.utc_now() |> DateTime.add(1, :second)

      :ok = AuthorizationCodeStore.store(code, short_expires_at, email, "challenge")

      Process.sleep(1100)

      assert {:error, :code_not_found} = AuthorizationCodeStore.retrieve_and_delete(code)
    end

    test "handles malformed JSON in Redis" do
      code = "test_code_malformed"
      key = "auth_code:#{code}"

      Redix.command(:redix, ["SETEX", key, 60, "not valid json"])

      assert {:error, :code_not_found} = AuthorizationCodeStore.retrieve_and_delete(code)
    end

    test "handles missing fields in stored JSON" do
      {code, expires_at} = AuthorizationCodeGenerator.generate()
      key = "auth_code:#{code}"
      ttl_seconds = DateTime.diff(expires_at, DateTime.utc_now(), :second) |> max(0)

      incomplete_json = Jason.encode!(%{email: "test@example.com"})

      Redix.command(:redix, ["SETEX", key, ttl_seconds, incomplete_json])

      assert {:error, :code_not_found} = AuthorizationCodeStore.retrieve_and_delete(code)
    end
  end
end
