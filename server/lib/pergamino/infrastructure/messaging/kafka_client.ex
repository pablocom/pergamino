defmodule Pergamino.Infrastructure.Messaging.KafkaClient do
  use Task

  def start_link(:skip), do: :ignore

  def start_link(_arg) do
    Task.start_link(fn ->
      kafka_config = Application.fetch_env!(:pergamino, :kafka)
      brokers = Keyword.fetch!(kafka_config, :brokers)
      client_id = Keyword.fetch!(kafka_config, :client_id)
      :ok = :brod.start_client(brokers, client_id, auto_start_producers: true)
    end)
  end
end
