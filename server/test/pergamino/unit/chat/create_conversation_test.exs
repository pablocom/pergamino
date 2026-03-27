defmodule Pergamino.Unit.Chat.CreateConversationTest do
  use ExUnit.Case, async: true

  import Mox

  alias Pergamino.Application.Chat.CreateConversation
  alias Pergamino.Infrastructure.Messaging.MessageBrokerMock

  setup :verify_on_exit!

  setup do
    stub(MessageBrokerMock, :publish, fn _, _, _ -> :ok end)
    Application.put_env(:pergamino, :message_broker, MessageBrokerMock)
    :ok
  end

  @valid_uuid "550e8400-e29b-41d4-a716-446655440000"

  describe "execute/2" do
    test "valid params return :ok and publish called with correct topic and key" do
      topic = Application.fetch_env!(:pergamino, :kafka) |> Keyword.fetch!(:conversations_topic)

      expect(MessageBrokerMock, :publish, fn ^topic, "chat:a@test.comb@test.com", _payload ->
        :ok
      end)

      assert :ok =
               CreateConversation.execute("a@test.com", %{
                 "id" => @valid_uuid,
                 "with" => "b@test.com"
               })
    end

    test "invalid from_email returns error" do
      assert {:error, :invalid_email} =
               CreateConversation.execute("not-an-email", %{
                 "id" => @valid_uuid,
                 "with" => "b@test.com"
               })
    end

    test "invalid with email returns error" do
      assert {:error, :invalid_email} =
               CreateConversation.execute("a@test.com", %{
                 "id" => @valid_uuid,
                 "with" => "not-an-email"
               })
    end

    test "invalid UUID id returns error" do
      assert {:error, :invalid_conversation_id} =
               CreateConversation.execute("a@test.com", %{
                 "id" => "not-a-uuid",
                 "with" => "b@test.com"
               })
    end

    test "broker failure returns error" do
      expect(MessageBrokerMock, :publish, fn _, _, _ -> {:error, :broker_unavailable} end)

      assert {:error, :broker_unavailable} =
               CreateConversation.execute("a@test.com", %{
                 "id" => @valid_uuid,
                 "with" => "b@test.com"
               })
    end

    test "conversation key is stable regardless of from/to order" do
      expect(MessageBrokerMock, :publish, 2, fn _topic, key, _payload ->
        send(self(), {:key, key})
        :ok
      end)

      CreateConversation.execute("b@test.com", %{"id" => @valid_uuid, "with" => "a@test.com"})
      CreateConversation.execute("a@test.com", %{"id" => @valid_uuid, "with" => "b@test.com"})

      keys =
        Enum.map(1..2, fn _ ->
          receive do
            {:key, key} -> key
          end
        end)

      assert length(Enum.uniq(keys)) == 1
    end
  end
end
