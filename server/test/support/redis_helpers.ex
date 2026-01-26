defmodule RedisHelpers do
  @moduledoc """
  Helper functions for Redis and DynamoDB operations in tests.
  Provides cleanup utilities to ensure test isolation.
  """

  @spec flush_authorization_codes() :: :ok
  def flush_authorization_codes do
    flush_keys_by_pattern("auth_code:*")
  end

  @spec flush_refresh_tokens() :: :ok
  def flush_refresh_tokens do
    table_name =
      Application.fetch_env!(:pergamino, :dynamodb)
      |> Keyword.fetch!(:refresh_tokens_table)

    case ExAws.Dynamo.scan(table_name) |> ExAws.request() do
      {:ok, %{"Items" => items}} when is_list(items) ->
        Enum.each(items, fn item ->
          case item do
            %{"token" => %{"S" => token}} ->
              key = %{"token" => token}
              ExAws.Dynamo.delete_item(table_name, key) |> ExAws.request()

            _ ->
              :ok
          end
        end)

        :ok

      _ ->
        :ok
    end
  end

  @spec flush_keys_by_pattern(String.t()) :: :ok
  defp flush_keys_by_pattern(pattern) do
    case Redix.command(:redix, ["KEYS", pattern]) do
      {:ok, keys} when is_list(keys) and length(keys) > 0 ->
        Redix.command(:redix, ["DEL" | keys])
        :ok

      _ ->
        :ok
    end
  end
end
