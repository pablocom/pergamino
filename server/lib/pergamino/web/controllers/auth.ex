defmodule Pergamino.Web.Controllers.Auth do
  use Pergamino, :controller

  alias Pergamino.Auth.Service
  alias Pergamino.Web.ProblemDetails

  def device_binding_link(conn, params) do
    with {:ok, email} <- fetch_email_param(params),
         {:ok, deeplink} <- Service.create_device_binding_link(email) do
      json(conn, %{deeplink: deeplink})
    else
      {:error, :missing_email} ->
        problem_details = ProblemDetails.build(:missing_email, conn.request_path)

        conn
        |> put_status(400)
        |> json(problem_details)

      {:error, :invalid_email} ->
        problem_details = ProblemDetails.build(:invalid_email_format, conn.request_path)

        conn
        |> put_status(400)
        |> json(problem_details)
    end
  end

  defp fetch_email_param(%{"email" => email}) when is_binary(email), do: {:ok, email}
  defp fetch_email_param(_), do: {:error, :missing_email}
end
