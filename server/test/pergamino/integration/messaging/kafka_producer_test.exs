defmodule Pergamino.Integration.Messaging.KafkaProducerTest do
  use ExUnit.Case, async: false

  alias Pergamino.Infrastructure.Messaging.KafkaProducer

  test "publishes message to conversations topic" do
    topic = Application.fetch_env!(:pergamino, :kafka) |> Keyword.fetch!(:conversations_topic)
    assert :ok = KafkaProducer.publish(topic, "chat:test", %{test: true})
  end

  test "publishes message to messages topic" do
    topic = Application.fetch_env!(:pergamino, :kafka) |> Keyword.fetch!(:messages_topic)
    assert :ok = KafkaProducer.publish(topic, "chat:test", %{test: true})
  end
end
