defmodule DynamoDBHelpers do
  @moduledoc """
  Helper functions for DynamoDB operations in tests.
  Provides table creation and management utilities.
  """

  @spec ensure_refresh_tokens_table() :: :ok | {:error, term()}
  def ensure_refresh_tokens_table do
    table_name =
      Application.fetch_env!(:pergamino, :dynamodb)
      |> Keyword.fetch!(:refresh_tokens_table)

    case table_exists?(table_name) do
      true ->
        :ok

      false ->
        create_refresh_tokens_table(table_name)
    end
  end

  defp table_exists?(table_name) do
    case ExAws.Dynamo.describe_table(table_name) |> ExAws.request() do
      {:ok, _} -> true
      {:error, _} -> false
    end
  end

  defp create_refresh_tokens_table(table_name) do
    case ExAws.Dynamo.create_table(
           table_name,
           [token: :hash],
           [token: :string],
           1,
           1
         )
         |> ExAws.request() do
      {:ok, _} ->
        wait_for_table_active(table_name)
        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp wait_for_table_active(table_name, retries \\ 10) do
    case ExAws.Dynamo.describe_table(table_name) |> ExAws.request() do
      {:ok, %{"Table" => %{"TableStatus" => "ACTIVE"}}} ->
        :ok

      _ when retries > 0 ->
        Process.sleep(100)
        wait_for_table_active(table_name, retries - 1)

      _ ->
        {:error, :timeout}
    end
  end
end
