defmodule Mix.Tasks.Setup.Dynamodb do
  use Mix.Task

  @shortdoc "Creates DynamoDB tables for local development"

  @impl Mix.Task
  def run(_args) do
    Application.ensure_all_started(:ex_aws)
    Application.ensure_all_started(:hackney)

    Mix.shell().info("Setting up DynamoDB tables...")

    table_name =
      Application.fetch_env!(:pergamino, :dynamodb)
      |> Keyword.fetch!(:refresh_tokens_table)

    with :ok <- create_refresh_tokens_table(table_name),
         :ok <- enable_ttl(table_name) do
      Mix.shell().info("DynamoDB tables ready.")
      :ok
    else
      {:error, reason} ->
        Mix.shell().error("Failed to set up DynamoDB tables: #{reason}")
        exit({:shutdown, 1})
    end
  end

  defp create_refresh_tokens_table(table_name) do
    key_schema = [token: :hash]
    key_definitions = [token: :string]

    case ExAws.Dynamo.create_table(table_name, key_schema, key_definitions,
           billing_mode: :pay_per_request
         )
         |> ExAws.request() do
      {:ok, _} ->
        Mix.shell().info("Created table \"#{table_name}\".")
        :ok

      {:error, {"ResourceInUseException", _}} ->
        Mix.shell().info("Table \"#{table_name}\" already exists, skipping creation.")
        :ok

      {:error, reason} ->
        {:error, inspect(reason)}
    end
  end

  defp enable_ttl(table_name) do
    case ExAws.Dynamo.update_time_to_live(table_name, "expires_at", true)
         |> ExAws.request() do
      {:ok, _} ->
        Mix.shell().info("Enabled TTL on \"expires_at\" for table \"#{table_name}\".")
        :ok

      {:error, {"ValidationException", message}} when is_binary(message) ->
        if String.contains?(message, "TimeToLive is already enabled") do
          Mix.shell().info("TTL already enabled on table \"#{table_name}\", skipping.")
          :ok
        else
          {:error, message}
        end

      {:error, reason} ->
        {:error, inspect(reason)}
    end
  end
end
