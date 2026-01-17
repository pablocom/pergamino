defmodule Pergamino.Web.Controllers.DeviceBinding do
  use Pergamino, :controller

  alias Pergamino.Application.DeviceBinding
  alias Pergamino.Domain.EmailAddress
  alias Pergamino.Infrastructure.Auth.TokenGenerator

  action_fallback(Pergamino.Web.Controllers.Fallback)

  def create(conn, params) do
    with {:ok, email_string} <- fetch_email_param(params),
         {:ok, email} <- EmailAddress.create(email_string),
         {:ok, token} <- TokenGenerator.generate(email),
         :ok <- DeviceBinding.send_binding_link(email_string, token) do
      send_resp(conn, 202, "")
    end
  end

  defp fetch_email_param(%{"email" => email}) when is_binary(email), do: {:ok, email}
  defp fetch_email_param(_), do: {:error, :missing_email}
end
