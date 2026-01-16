defmodule Pergamino.Web.Controllers.Auth do
  use Pergamino, :controller

  alias Pergamino.Auth.Service

  action_fallback(Pergamino.Web.Controllers.Fallback)

  def device_binding_link(conn, params) do
    with {:ok, email} <- fetch_email_param(params),
         {:ok, deeplink} <- Service.create_device_binding_link(email) do
      json(conn, %{deeplink: deeplink})
    end
  end

  defp fetch_email_param(%{"email" => email}) when is_binary(email), do: {:ok, email}
  defp fetch_email_param(_), do: {:error, :missing_email}
end
