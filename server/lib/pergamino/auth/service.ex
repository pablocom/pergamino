defmodule Pergamino.Auth.Service do
  alias Pergamino.Domain.Email
  alias Pergamino.Auth.Token

  @spec create_device_binding_link(String.t()) :: {:ok, String.t()} | {:error, any()}
  def create_device_binding_link(email) do
    with {:ok, validated_email} <- Email.create(email),
         {:ok, token} <- Token.generate(validated_email) do
      {:ok, "pergamino://bind?token=#{token}"}
    else
      {:error, _} = error -> error
    end
  end

  @spec bind_device(String.t(), String.t()) :: {:ok, String.t()} | {:error, any()}
  def bind_device(_token, _public_key) do
    {:error, :not_implemented}
  end
end
