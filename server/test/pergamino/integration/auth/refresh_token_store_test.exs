defmodule Pergamino.Integration.Auth.RefreshTokenStoreTest do
  use ExUnit.Case, async: false

  import RedisHelpers
  import DynamoDBHelpers

  alias Pergamino.Domain.EmailAddress
  alias Pergamino.Infrastructure.Auth.{RefreshToken, RefreshTokenStore}
  alias Pergamino.Core.Clock

  setup_all do
    ensure_refresh_tokens_table()
    :ok
  end

  setup do
    on_exit(fn ->
      flush_refresh_tokens()
    end)

    :ok
  end

  describe "Refresh token store" do
    test "stores refresh token with correct attributes" do
      {:ok, email} = EmailAddress.create("test@example.com")
      {token, expires_at} = RefreshToken.generate()

      assert :ok = RefreshTokenStore.store(token, expires_at, email)

      table_name = get_table_name()
      key = %{"token" => token}

      {:ok, result} = ExAws.Dynamo.get_item(table_name, key) |> ExAws.request()

      assert %{"Item" => item} = result
      assert %{"token" => %{"S" => ^token}} = item
      assert %{"email" => %{"S" => "test@example.com"}} = item
      assert %{"expires_at" => %{"N" => _ttl}} = item
    end

    test "stores token with correct TTL as Unix timestamp" do
      {:ok, email} = EmailAddress.create("test@example.com")
      {token, expires_at} = RefreshToken.generate()

      :ok = RefreshTokenStore.store(token, expires_at, email)

      table_name = get_table_name()
      key = %{"token" => token}

      {:ok, %{"Item" => item}} = ExAws.Dynamo.get_item(table_name, key) |> ExAws.request()

      assert %{"expires_at" => %{"N" => ttl_string}} = item
      {ttl, ""} = Integer.parse(ttl_string)

      expected_ttl = DateTime.to_unix(expires_at)
      assert ttl == expected_ttl
    end

    test "atomically retrieves and deletes token" do
      {:ok, email} = EmailAddress.create("test@example.com")
      {token, expires_at} = RefreshToken.generate()

      :ok = RefreshTokenStore.store(token, expires_at, email)

      assert {:ok, "test@example.com"} = RefreshTokenStore.retrieve_and_delete(token)

      assert {:error, :token_not_found} = RefreshTokenStore.retrieve_and_delete(token)
    end

    test "returns token_not_found error for non-existent token" do
      assert {:error, :token_not_found} =
               RefreshTokenStore.retrieve_and_delete("nonexistent_token")
    end

    test "returns error for expired token" do
      {:ok, email} = EmailAddress.create("test@example.com")
      {token, _expires_at} = RefreshToken.generate()

      past_time = Clock.utc_now() |> DateTime.add(-1, :second)

      :ok = RefreshTokenStore.store(token, past_time, email)

      assert {:error, :token_not_found} = RefreshTokenStore.retrieve_and_delete(token)
    end

    test "stores multiple tokens for same email" do
      {:ok, email} = EmailAddress.create("test@example.com")
      {token1, expires_at1} = RefreshToken.generate()
      {token2, expires_at2} = RefreshToken.generate()

      assert :ok = RefreshTokenStore.store(token1, expires_at1, email)
      assert :ok = RefreshTokenStore.store(token2, expires_at2, email)

      assert {:ok, "test@example.com"} = RefreshTokenStore.retrieve_and_delete(token1)
      assert {:ok, "test@example.com"} = RefreshTokenStore.retrieve_and_delete(token2)
    end

    test "stores tokens for different emails" do
      {:ok, email1} = EmailAddress.create("user1@example.com")
      {:ok, email2} = EmailAddress.create("user2@example.com")

      {token1, expires_at1} = RefreshToken.generate()
      {token2, expires_at2} = RefreshToken.generate()

      :ok = RefreshTokenStore.store(token1, expires_at1, email1)
      :ok = RefreshTokenStore.store(token2, expires_at2, email2)

      assert {:ok, "user1@example.com"} = RefreshTokenStore.retrieve_and_delete(token1)
      assert {:ok, "user2@example.com"} = RefreshTokenStore.retrieve_and_delete(token2)
    end

    test "normalizes email to lowercase when storing" do
      {:ok, email} = EmailAddress.create("Test@Example.COM")
      {token, expires_at} = RefreshToken.generate()

      :ok = RefreshTokenStore.store(token, expires_at, email)

      assert {:ok, "test@example.com"} = RefreshTokenStore.retrieve_and_delete(token)
    end
  end

  defp get_table_name do
    Application.fetch_env!(:pergamino, :dynamodb)
    |> Keyword.fetch!(:refresh_tokens_table)
  end
end
