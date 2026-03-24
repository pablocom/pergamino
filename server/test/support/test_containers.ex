defmodule Pergamino.TestContainers do
  alias Testcontainers.{Container, RedisContainer}

  @spec start() :: :ok
  def start do
    {:ok, _} = Testcontainers.start_link()

    redis_url = start_redis()
    dynamo_port = start_dynamodb()

    reconfigure_redis(redis_url)
    reconfigure_dynamodb(dynamo_port)
    create_refresh_tokens_table()

    :ok
  end

  defp start_redis do
    {:ok, container} =
      RedisContainer.new()
      |> Testcontainers.start_container()

    RedisContainer.connection_url(container)
  end

  defp start_dynamodb do
    {:ok, container} =
      Container.new("amazon/dynamodb-local:latest")
      |> Container.with_exposed_port(8000)
      |> Container.with_cmd(["-jar", "DynamoDBLocal.jar", "-sharedDb", "-inMemory"])
      |> Container.with_waiting_strategy(
        Testcontainers.LogWaitStrategy.new(~r/CorsParams/, 30_000)
      )
      |> Testcontainers.start_container()

    Container.mapped_port(container, 8000)
  end

  defp reconfigure_redis(redis_url) do
    Application.put_env(:pergamino, :redis, url: redis_url, pool_size: 2)

    :ok = Supervisor.terminate_child(Pergamino.Supervisor, Redix)
    :ok = Supervisor.delete_child(Pergamino.Supervisor, Redix)
    {:ok, _} = Supervisor.start_child(Pergamino.Supervisor, {Redix, {redis_url, [name: :redix]}})
  end

  defp reconfigure_dynamodb(port) do
    Application.put_env(:ex_aws, :dynamodb,
      scheme: "http://",
      host: "localhost",
      port: port,
      region: "us-east-1"
    )
  end

  defp create_refresh_tokens_table do
    table_name =
      Application.fetch_env!(:pergamino, :dynamodb)
      |> Keyword.fetch!(:refresh_tokens_table)

    case ExAws.Dynamo.create_table(table_name, [token: :hash], [token: :string], 1, 1)
         |> ExAws.request() do
      {:ok, _} -> wait_for_table_active(table_name)
      {:error, {"ResourceInUseException", _}} -> :ok
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
        raise "DynamoDB table #{table_name} did not become active within timeout"
    end
  end
end
