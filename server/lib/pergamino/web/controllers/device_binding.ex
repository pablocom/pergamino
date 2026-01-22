defmodule Pergamino.Web.Controllers.DeviceBinding do
  use Pergamino, :controller

  alias Pergamino.Application.DeviceBinding

  action_fallback(Pergamino.Web.ErrorHandler)

  def create(conn, params) do
    with {:ok, email_string} <- fetch_email_param(params),
         :ok <- DeviceBinding.send_binding_link(email_string) do
      send_resp(conn, 202, "")
    end
  end

  defp fetch_email_param(%{"email" => email}) when is_binary(email), do: {:ok, email}
  defp fetch_email_param(_), do: {:error, :missing_email}
end
