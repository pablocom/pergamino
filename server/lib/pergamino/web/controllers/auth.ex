defmodule Pergamino.Web.Controllers.Auth do
  use Pergamino, :controller

  def login(conn, _params) do
    json(conn, %{deeplink: "myapp://verify?token=secret_123"})
  end
end
