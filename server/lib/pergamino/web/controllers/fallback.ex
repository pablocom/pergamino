defmodule Pergamino.Web.Controllers.Fallback do
  use Pergamino, :controller

  alias Pergamino.Web.ErrorHandler

  def call(conn, {:error, reason}) do
    ErrorHandler.handle_error(conn, {:error, reason})
  end

  def call(conn, other) do
    ErrorHandler.handle_error(conn, other)
  end
end
