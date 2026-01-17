defmodule Pergamino.Auth.Service do
  alias Pergamino.Domain.Email
  alias Pergamino.Auth.Token
  alias Pergamino.Auth.DeviceBindingEmail
  alias Pergamino.Mailer

  @spec create_device_binding_link(String.t()) :: :ok | {:error, atom()}
  def create_device_binding_link(email_string) do
    with {:ok, email} <- Email.create(email_string),
         {:ok, token} <- Token.generate(email),
         email_struct <- DeviceBindingEmail.build(email.address, "pergamino://bind?token=#{token}"),
         {:ok, _metadata} <- Mailer.deliver(email_struct) do
      :ok
    else
      {:error, reason} when reason in [:invalid_email, :token_generation_failed] ->
        {:error, reason}

      {:error, _delivery_error} ->
        {:error, :email_delivery_failed}
    end
  end

  @spec bind_device(String.t(), String.t()) :: {:ok, String.t()} | {:error, any()}
  def bind_device(_token, _public_key) do
    {:error, :not_implemented}
  end
end
