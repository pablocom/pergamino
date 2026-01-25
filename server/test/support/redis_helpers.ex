defmodule RedisHelpers do
  @moduledoc """
  Helper functions for Redis operations in tests.
  Provides cleanup utilities to ensure test isolation.
  """

  @spec flush_authorization_codes() :: :ok
  def flush_authorization_codes do
    flush_keys_by_pattern("auth_code:*")
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
