defmodule Pergamino.Component.Web.Channels.ChatChannelTest do
  use Pergamino.ChannelCase, async: true

  import Mox

  alias Pergamino.Domain.EmailAddress
  alias Pergamino.Infrastructure.Auth.TokenGenerator
  alias Pergamino.Infrastructure.Messaging.MessageBrokerMock
  alias Pergamino.Web.Channels.UserSocket

  setup :verify_on_exit!

  setup do
    stub(MessageBrokerMock, :publish, fn _, _, _ -> :ok end)
    Application.put_env(:pergamino, :message_broker, MessageBrokerMock)

    {:ok, email} = EmailAddress.create("test@example.com")
    {:ok, token} = TokenGenerator.generate(email)

    {:ok, socket} = connect(UserSocket, %{"token" => token})
    {:ok, _, socket} = subscribe_and_join(socket, "chat:lobby")

    {:ok, socket: socket, token: token}
  end

  @valid_uuid "550e8400-e29b-41d4-a716-446655440000"

  describe "connect/3" do
    test "connect with valid token assigns email" do
      {:ok, email} = EmailAddress.create("test@example.com")
      {:ok, token} = TokenGenerator.generate(email)

      assert {:ok, socket} = connect(UserSocket, %{"token" => token})
      assert socket.assigns.email == "test@example.com"
    end

    test "connect with invalid token returns error" do
      assert :error = connect(UserSocket, %{"token" => "invalid.token.here"})
    end

    test "connect with no token returns error" do
      assert :error = connect(UserSocket, %{})
    end
  end

  describe "create_conversation" do
    test "valid UUID and email returns ok reply", %{socket: socket} do
      ref =
        push(socket, "create_conversation", %{
          "id" => @valid_uuid,
          "with" => "other@example.com"
        })

      assert_reply(ref, :ok, %{})
    end

    test "invalid UUID returns error reply", %{socket: socket} do
      ref =
        push(socket, "create_conversation", %{
          "id" => "not-a-uuid",
          "with" => "other@example.com"
        })

      assert_reply(ref, :error, %{reason: :invalid_conversation_id})
    end

    test "invalid with email returns error reply", %{socket: socket} do
      ref =
        push(socket, "create_conversation", %{
          "id" => @valid_uuid,
          "with" => "not-an-email"
        })

      assert_reply(ref, :error, %{reason: :invalid_email})
    end
  end

  describe "send_message" do
    test "valid params returns ok reply", %{socket: socket} do
      ref =
        push(socket, "send_message", %{
          "to" => "other@example.com",
          "text" => "Hello!"
        })

      assert_reply(ref, :ok, %{})
    end

    test "text over 1500 chars returns error reply", %{socket: socket} do
      ref =
        push(socket, "send_message", %{
          "to" => "other@example.com",
          "text" => String.duplicate("a", 1501)
        })

      assert_reply(ref, :error, %{reason: :invalid_message_text})
    end

    test "empty text returns error reply", %{socket: socket} do
      ref =
        push(socket, "send_message", %{
          "to" => "other@example.com",
          "text" => ""
        })

      assert_reply(ref, :error, %{reason: :invalid_message_text})
    end

    test "invalid to email returns error reply", %{socket: socket} do
      ref =
        push(socket, "send_message", %{
          "to" => "not-an-email",
          "text" => "Hello!"
        })

      assert_reply(ref, :error, %{reason: :invalid_email})
    end

    test "broker failure returns error reply", %{socket: socket} do
      expect(MessageBrokerMock, :publish, fn _, _, _ -> {:error, :broker_unavailable} end)

      ref =
        push(socket, "send_message", %{
          "to" => "other@example.com",
          "text" => "Hello!"
        })

      assert_reply(ref, :error, %{reason: :broker_unavailable})
    end
  end
end
