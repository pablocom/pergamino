defmodule Pergamino.Infrastructure.Messaging.KafkaProducer do
  @behaviour Pergamino.Infrastructure.Messaging.MessageBrokerBehaviour

  @spec publish(String.t(), String.t(), map()) :: :ok | {:error, :broker_unavailable}
  def publish(topic, key, payload) when is_binary(topic) and is_binary(key) and is_map(payload) do
    client_id = Application.fetch_env!(:pergamino, :kafka) |> Keyword.fetch!(:client_id)
    encoded = Jason.encode!(payload)

    case :brod.produce_sync(client_id, topic, :hash, key, encoded) do
      :ok -> :ok
      {:ok, _} -> :ok
      {:error, _} -> {:error, :broker_unavailable}
    end
  rescue
    _ -> {:error, :broker_unavailable}
  end
end
