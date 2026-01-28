defmodule Pergamino.Web.ErrorHandler do
  use Pergamino, :controller

  alias Pergamino.Web.Errors.ProblemDetailsRenderer
  alias Pergamino.Web.Errors.ValidationError
  alias Pergamino.Web.Errors.AuthenticationError
  alias Pergamino.Web.Errors.InfrastructureError

  require Logger

  @spec call(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def call(conn, {:error, errors}) when is_list(errors) do
    handle_multiple_errors(conn, errors)
  end

  def call(conn, {:error, %ValidationError{} = error}) do
    handle_structured_error(conn, error)
  end

  def call(conn, {:error, error}) when is_struct(error) do
    handle_structured_error(conn, error)
  end

  def call(conn, {:error, error_code}) when is_atom(error_code) do
    error = map_legacy_error(error_code)
    handle_structured_error(conn, error)
  end

  def call(conn, error) do
    handle_unknown_error(conn, error)
  end

  defp handle_structured_error(conn, error) do
    problem_details = ProblemDetailsRenderer.render(error)

    conn
    |> put_status(problem_details.status)
    |> json(problem_details)
  end

  defp handle_multiple_errors(conn, errors) do
    rendered_errors =
      Enum.map(errors, fn error ->
        rendered = ProblemDetailsRenderer.render(error)
        %{
          field: rendered.extensions.field,
          code: rendered.extensions.code,
          detail: rendered.detail
        }
      end)

    problem_details = %{
      type: "https://pergamino.app/errors/validation",
      status: 400,
      detail: "Request validation failed",
      extensions: %{
        errors: rendered_errors
      }
    }

    conn
    |> put_status(400)
    |> json(problem_details)
  end

  defp handle_unknown_error(conn, error) do
    Logger.error("Unhandled error in #{conn.request_path}: #{inspect(error)}")

    problem_details = %{
      type: "https://pergamino.app/errors/internal-server-error",
      status: 500,
      detail: "An unexpected error occurred",
      extensions: %{code: :internal_server_error}
    }

    conn
    |> put_status(500)
    |> json(problem_details)
  end

  defp map_legacy_error(:invalid_authorization_code), do: AuthenticationError.invalid_authorization_code()
  defp map_legacy_error(:invalid_refresh_token), do: AuthenticationError.invalid_refresh_token()
  defp map_legacy_error(:invalid_email), do: ValidationError.invalid_format(:email, "Email format is invalid")
  defp map_legacy_error(:redis_unavailable), do: InfrastructureError.service_unavailable(:redis)
  defp map_legacy_error(:dynamodb_unavailable), do: InfrastructureError.service_unavailable(:dynamodb)
  defp map_legacy_error(:email_delivery_failed), do: InfrastructureError.service_unavailable(:email)
end
