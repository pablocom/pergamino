defmodule Pergamino.Application.Chat.SendMessage do
  alias Pergamino.Core.Clock
  alias Pergamino.Domain.{EmailAddress, MessageText}
  alias Pergamino.Infrastructure.Messaging.KafkaProducer

  @spec execute(String.t(), map()) :: :ok | {:error, atom()}
  def execute(from_email_string, params) do
    with {:ok, from_email} <- EmailAddress.create(from_email_string),
         {:ok, to_email} <- EmailAddress.create(Map.get(params, "to", "")),
         {:ok, text} <- MessageText.create(Map.get(params, "text", "")) do
      broker().publish(
        messages_topic(),
        conversation_key(from_email, to_email),
        %{
          from: from_email.address,
          to: to_email.address,
          text: text.content,
          sent_at: DateTime.to_iso8601(Clock.utc_now())
        }
      )
    end
  end

  defp broker, do: Application.get_env(:pergamino, :message_broker, KafkaProducer)

  defp messages_topic,
    do: Application.fetch_env!(:pergamino, :kafka) |> Keyword.fetch!(:messages_topic)

  defp conversation_key(%EmailAddress{address: a}, %EmailAddress{address: b}) do
    [a, b] |> Enum.sort() |> then(fn [u1, u2] -> "chat:#{u1}#{u2}" end)
  end
end
