defmodule Pergamino.Web.Channels.ChatChannel do
  use Pergamino, :channel

  alias Pergamino.Application.Chat.{CreateConversation, SendMessage}

  @impl true
  def join("chat:" <> _, _payload, socket), do: {:ok, socket}

  @impl true
  def handle_in("create_conversation", params, socket) do
    case CreateConversation.execute(socket.assigns.email, params) do
      :ok -> {:reply, {:ok, %{}}, socket}
      {:error, reason} -> {:reply, {:error, %{reason: reason}}, socket}
    end
  end

  def handle_in("send_message", params, socket) do
    case SendMessage.execute(socket.assigns.email, params) do
      :ok -> {:reply, {:ok, %{}}, socket}
      {:error, reason} -> {:reply, {:error, %{reason: reason}}, socket}
    end
  end
end
