defmodule Pergamino.Integration.Auth.AuthorizationCodeStoreTest do
  use ExUnit.Case, async: false

  import Mox

  alias Pergamino.Domain.EmailAddress
  alias Pergamino.Infrastructure.Auth.{AuthorizationCode, AuthorizationCodeStore}
  alias Pergamino.Core.ClockMock

  @pkce_challenge "test_challenge_string"
  @frozen_now ~U[2024-06-15 12:00:00Z]

  setup do
    on_exit(fn ->
      Application.delete_env(:pergamino, :clock_adapter)
      flush_authorization_codes()
    end)

    :ok
  end

  describe "Authorization code store" do
    test "stores authorization code with correct TTL" do
      stub(ClockMock, :utc_now, fn -> @frozen_now end)
      Application.put_env(:pergamino, :clock_adapter, ClockMock)

      {:ok, email} = EmailAddress.create("test@example.com")
      {code, expires_at} = AuthorizationCode.generate()
      challenge = @pkce_challenge

      assert :ok = AuthorizationCodeStore.store(code, expires_at, email, challenge)

      key = "auth_code:#{code}"
      {:ok, stored_value} = Redix.command(:redix, ["GET", key])
      {:ok, ttl} = Redix.command(:redix, ["TTL", key])

      assert is_binary(stored_value)
      assert ttl == 300

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

    test "does not store code when expiration is already in the past" do
      frozen_now = @frozen_now
      already_expired = DateTime.add(frozen_now, -10, :second)

      stub(ClockMock, :utc_now, fn -> frozen_now end)
      Application.put_env(:pergamino, :clock_adapter, ClockMock)

      {code, _expires_at} = AuthorizationCode.generate()
      {:ok, email} = EmailAddress.create("test@example.com")

      assert :ok = AuthorizationCodeStore.store(code, already_expired, email, "challenge")

      assert {:error, :code_not_found} = AuthorizationCodeStore.retrieve_and_delete(code)
    end
  end

  defp flush_authorization_codes do
    case Redix.command(:redix, ["KEYS", "auth_code:*"]) do
      {:ok, keys} when keys != [] -> Redix.command(:redix, ["DEL" | keys])
      _ -> :ok
    end
  end
end
