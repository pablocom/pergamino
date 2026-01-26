defmodule Pergamino.Infrastructure.Auth.RefreshTokenStore do
  @behaviour Pergamino.Infrastructure.Auth.RefreshTokenStoreBehaviour

  alias Pergamino.Domain.EmailAddress
  alias Pergamino.Core.Clock

  @spec store(
          token :: String.t(),
          expires_at :: DateTime.t(),
          email :: EmailAddress.t()
        ) ::
          :ok | {:error, :dynamodb_unavailable}
  def store(token, expires_at, %EmailAddress{address: email}) when is_binary(token) do
    ttl = DateTime.to_unix(expires_at)

    item = %{
      "token" => token,
      "email" => email,
      "expires_at" => ttl
    }

    case ExAws.Dynamo.put_item(table_name(), item) |> ExAws.request() do
      {:ok, _} -> :ok
      {:error, _reason} -> {:error, :dynamodb_unavailable}
    end
  end

  @spec retrieve_and_delete(String.t()) ::
          {:ok, String.t()}
          | {:error, :token_not_found | :dynamodb_unavailable}
  def retrieve_and_delete(token) do
    key = %{"token" => token}

    case ExAws.Dynamo.get_item(table_name(), key) |> ExAws.request() do
      {:ok, %{"Item" => item}} when map_size(item) > 0 ->
        with {:ok, email} <- extract_email(item),
             :ok <- verify_not_expired(item),
             {:ok, _} <- delete_token(token) do
          {:ok, email}
        else
          {:error, :expired} -> {:error, :token_not_found}
          {:error, _} -> {:error, :dynamodb_unavailable}
        end

      {:ok, _} ->
        {:error, :token_not_found}

      {:error, _reason} ->
        {:error, :dynamodb_unavailable}
    end
  end

  defp table_name do
    Application.fetch_env!(:pergamino, :dynamodb)
    |> Keyword.fetch!(:refresh_tokens_table)
  end

  defp extract_email(%{"email" => %{"S" => email}}) when is_binary(email), do: {:ok, email}
  defp extract_email(_), do: {:error, :invalid_data}

  defp verify_not_expired(%{"expires_at" => %{"N" => expires_at_string}}) do
    case Integer.parse(expires_at_string) do
      {expires_at_unix, ""} ->
        expires_at = DateTime.from_unix!(expires_at_unix)
        now = Clock.utc_now()

        if DateTime.compare(expires_at, now) == :gt do
          :ok
        else
          {:error, :expired}
        end

      _ ->
        {:error, :invalid_data}
    end
  end

  defp verify_not_expired(_), do: {:error, :invalid_data}

  defp delete_token(token) do
    key = %{"token" => token}

    case ExAws.Dynamo.delete_item(table_name(), key) |> ExAws.request() do
      {:ok, _} -> {:ok, :deleted}
      {:error, reason} -> {:error, reason}
    end
  end
end
