defmodule Pergamino.Unit.Chat.SendMessageTest do
  use ExUnit.Case, async: true

  import Mox

  alias Pergamino.Application.Chat.SendMessage
  alias Pergamino.Infrastructure.Messaging.MessageBrokerMock

  setup :verify_on_exit!

  setup do
    stub(MessageBrokerMock, :publish, fn _, _, _ -> :ok end)
    Application.put_env(:pergamino, :message_broker, MessageBrokerMock)
    :ok
  end

  describe "execute/2" do
    test "valid params return :ok and publish called with correct topic and key" do
      topic = Application.fetch_env!(:pergamino, :kafka) |> Keyword.fetch!(:messages_topic)

      expect(MessageBrokerMock, :publish, fn ^topic, "chat:a@test.comb@test.com", _payload ->
        :ok
      end)

      assert :ok =
               SendMessage.execute("a@test.com", %{
                 "to" => "b@test.com",
                 "text" => "Hello!"
               })
    end

    test "invalid from_email returns error" do
      assert {:error, :invalid_email} =
               SendMessage.execute("not-an-email", %{
                 "to" => "b@test.com",
                 "text" => "Hello!"
               })
    end

    test "invalid to email returns error" do
      assert {:error, :invalid_email} =
               SendMessage.execute("a@test.com", %{
                 "to" => "not-an-email",
                 "text" => "Hello!"
               })
    end

    test "empty text returns error" do
      assert {:error, :invalid_message_text} =
               SendMessage.execute("a@test.com", %{
                 "to" => "b@test.com",
                 "text" => ""
               })
    end

    test "text over 1500 chars returns error" do
      long_text = String.duplicate("a", 1501)

      assert {:error, :invalid_message_text} =
               SendMessage.execute("a@test.com", %{
                 "to" => "b@test.com",
                 "text" => long_text
               })
    end

    test "broker failure surfaces correctly" do
      expect(MessageBrokerMock, :publish, fn _, _, _ -> {:error, :broker_unavailable} end)

      assert {:error, :broker_unavailable} =
               SendMessage.execute("a@test.com", %{
                 "to" => "b@test.com",
                 "text" => "Hello!"
               })
    end
  end
end
