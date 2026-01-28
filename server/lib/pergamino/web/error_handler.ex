defmodule Pergamino.Web.ErrorHandler do
  use Pergamino, :controller

  alias Pergamino.Web.ProblemDetails

  require Logger

  @spec call(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def call(conn, {:error, error_code}) when is_atom(error_code) do
    {:ok, problem_details} = ProblemDetails.build(error_code, conn.request_path)

    conn
    |> put_status(problem_details.status)
    |> json(problem_details)
  end

  def call(conn, error) do
    handle_unknown_error(conn, error)
  end

  defp handle_unknown_error(conn, error) do
    Logger.error("Unhandled error in #{conn.request_path}: #{inspect(error)}")

    {:ok, problem_details} = ProblemDetails.build(:internal_server_error, conn.request_path)

    conn
    |> put_status(problem_details.status)
    |> json(problem_details)
  end
end
