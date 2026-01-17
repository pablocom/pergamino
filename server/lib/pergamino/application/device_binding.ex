defmodule Pergamino.Application.DeviceBinding do
  alias Pergamino.Domain.EmailAddress
  alias Pergamino.Infrastructure.Messaging.EmailSender

  @spec send_binding_link(String.t(), String.t()) :: :ok | {:error, atom()}
  def send_binding_link(email_string, token) do
    with {:ok, email} <- EmailAddress.create(email_string),
         {:ok, _} <- EmailSender.send_device_binding_email(email, build_deeplink(token)) do
      :ok
    else
      {:error, :invalid_email} ->
        {:error, :invalid_email}

      {:error, _delivery_error} ->
        {:error, :email_delivery_failed}
    end
  end

  @spec build_deeplink(String.t()) :: String.t()
  defp build_deeplink(token), do: "pergamino://bind?token=#{token}"
end
