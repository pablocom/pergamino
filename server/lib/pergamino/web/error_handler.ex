defmodule Pergamino.Web.ErrorHandler do
  use Pergamino, :controller

  alias Pergamino.Web.ProblemDetails
  require Logger

  @spec call(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def call(conn, {:error, error_code}) when is_atom(error_code) do
    case error_mapping(error_code) do
      {:ok, status, problem_details_code} ->
        render_problem_details(conn, status, problem_details_code)

      :unknown ->
        handle_unknown_error(conn, {:error, error_code})
    end
  end

  def call(conn, error) do
    handle_unknown_error(conn, error)
  end

  defp error_mapping(error_code) do
    case error_code do
      :missing_email -> {:ok, 400, :missing_email}
      :invalid_email -> {:ok, 400, :invalid_email_format}
      :token_generation_failed -> {:ok, 500, :internal_server_error}
      :email_delivery_failed -> {:ok, 503, :service_unavailable}
      :not_implemented -> {:ok, 501, :not_implemented}
      _ -> :unknown
    end
  end

  defp render_problem_details(conn, status, error_code) do
    problem_details = ProblemDetails.build(error_code, conn.request_path)

    conn
    |> put_status(status)
    |> json(problem_details)
  end

  defp handle_unknown_error(conn, error) do
    Logger.error("Unhandled error in #{conn.request_path}: #{inspect(error)}")

    problem_details = ProblemDetails.build(:internal_server_error, conn.request_path)

    conn
    |> put_status(500)
    |> json(problem_details)
  end
end
