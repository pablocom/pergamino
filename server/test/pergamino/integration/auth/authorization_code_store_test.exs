defmodule Pergamino.Integration.Auth.AuthorizationCodeStoreTest do
  use ExUnit.Case, async: false

  import RedisHelpers

  alias Pergamino.Domain.EmailAddress
  alias Pergamino.Infrastructure.Auth.{AuthorizationCode, AuthorizationCodeStore}
  alias Pergamino.Core.Clock

  @pkce_challenge "test_challenge_string"

  setup do
    on_exit(fn ->
      flush_authorization_codes()
    end)

    :ok
  end

  describe "Authorization code store" do
    test "stores authorization code with correct TTL" do
      {:ok, email} = EmailAddress.create("test@example.com")
      {code, expires_at} = AuthorizationCode.generate()
      challenge = @pkce_challenge

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

    test "atomically retrieves and deletes code" do
      {:ok, email} = EmailAddress.create("test@example.com")
      {code, expires_at} = AuthorizationCode.generate()
      challenge = @pkce_challenge

      :ok = AuthorizationCodeStore.store(code, expires_at, email, challenge)

      assert {:ok, "test@example.com", ^challenge} =
               AuthorizationCodeStore.retrieve_and_delete(code)

      assert {:error, :code_not_found} = AuthorizationCodeStore.retrieve_and_delete(code)
    end

    test "returns code_not_found error for non-existent code" do
      assert {:error, :code_not_found} =
               AuthorizationCodeStore.retrieve_and_delete("nonexistent_code")
    end

    test "returns error for expired code after TTL" do
      {code, _expires_at} = AuthorizationCode.generate()
      {:ok, email} = EmailAddress.create("test@example.com")

      short_expires_at = Clock.utc_now() |> DateTime.add(1, :second)

      :ok = AuthorizationCodeStore.store(code, short_expires_at, email, "challenge")

      Process.sleep(1100)

      assert {:error, :code_not_found} = AuthorizationCodeStore.retrieve_and_delete(code)
    end
  end
end
