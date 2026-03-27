defmodule Pergamino.Web.Channels.UserSocket do
  use Phoenix.Socket

  alias Pergamino.Infrastructure.Auth.TokenGenerator

  channel("chat:*", Pergamino.Web.Channels.ChatChannel)

  @impl true
  def connect(%{"token" => token}, socket, _connect_info) do
    case TokenGenerator.verify(token) do
      {:ok, %{"email" => email}} -> {:ok, assign(socket, :email, email)}
      {:error, _} -> :error
    end
  end

  def connect(_, _socket, _connect_info), do: :error

  @impl true
  def id(socket), do: "user_socket:#{socket.assigns.email}"
end
