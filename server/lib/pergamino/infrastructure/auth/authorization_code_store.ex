defmodule Pergamino.Infrastructure.Auth.AuthorizationCodeStore do
  alias Pergamino.Domain.EmailAddress

  @redis_key_prefix "auth_code:"

  @spec store(
          code :: String.t(),
          expires_at :: DateTime.t(),
          email :: EmailAddress.t(),
          challenge :: String.t()
        ) ::
          :ok | {:error, :redis_unavailable}
  def store(code, expires_at, %EmailAddress{address: email}, challenge)
      when is_binary(code) and is_binary(challenge) do
    key = redis_key(code)
    ttl_seconds = calculate_ttl(expires_at)

    value =
      Jason.encode!(%{
        email: email,
        code_challenge: challenge
      })

    case Redix.command(:redix, ["SETEX", key, ttl_seconds, value]) do
      {:ok, "OK"} -> :ok
      {:error, _reason} -> {:error, :redis_unavailable}
    end
  end

  @spec retrieve_and_delete(String.t()) ::
          {:ok, String.t(), String.t()}
          | {:error, :code_not_found | :redis_unavailable}
  def retrieve_and_delete(code) do
    key = redis_key(code)

    case Redix.pipeline(:redix, [["GET", key], ["DEL", key]]) do
      {:ok, [nil, _]} ->
        {:error, :code_not_found}

      {:ok, [value_json, 1]} when is_binary(value_json) ->
        parse_stored_value(value_json)

      {:ok, _unexpected} ->
        {:error, :code_not_found}

      {:error, _reason} ->
        {:error, :redis_unavailable}
    end
  end

  defp redis_key(code), do: "#{@redis_key_prefix}#{code}"

  defp calculate_ttl(expires_at) do
    DateTime.diff(expires_at, DateTime.utc_now(), :second)
    |> max(0)
  end

  defp parse_stored_value(value_json) do
    case Jason.decode(value_json) do
      {:ok, %{"email" => email, "code_challenge" => challenge}}
      when is_binary(email) and is_binary(challenge) ->
        {:ok, email, challenge}

      _ ->
        {:error, :code_not_found}
    end
  end
end
