defmodule Pergamino.Application.Chat.CreateConversation do
  alias Pergamino.Core.Clock
  alias Pergamino.Domain.{ConversationId, EmailAddress}
  alias Pergamino.Infrastructure.Messaging.KafkaProducer

  @spec execute(String.t(), map()) :: :ok | {:error, atom()}
  def execute(from_email_string, params) do
    with {:ok, from_email} <- EmailAddress.create(from_email_string),
         {:ok, to_email} <- EmailAddress.create(Map.get(params, "with", "")),
         {:ok, conv_id} <- ConversationId.create(Map.get(params, "id", "")) do
      broker().publish(
        conversations_topic(),
        conversation_key(from_email, to_email),
        %{
          id: conv_id.value,
          initiator: from_email.address,
          participant: to_email.address,
          created_at: DateTime.to_iso8601(Clock.utc_now())
        }
      )
    end
  end

  defp broker, do: Application.get_env(:pergamino, :message_broker, KafkaProducer)

  defp conversations_topic,
    do: Application.fetch_env!(:pergamino, :kafka) |> Keyword.fetch!(:conversations_topic)

  defp conversation_key(%EmailAddress{address: a}, %EmailAddress{address: b}) do
    [a, b] |> Enum.sort() |> then(fn [u1, u2] -> "chat:#{u1}#{u2}" end)
  end
end
