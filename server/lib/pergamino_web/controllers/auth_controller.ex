defmodule PergaminoWeb.AuthController do
  use PergaminoWeb, :controller

  @doc """
  Returns a hardcoded deeplink for authentication.
  This is a temporary first iteration implementation.
  """
  def login(conn, _params) do
    json(conn, %{deeplink: "myapp://verify?token=secret_123"})
  end
end
