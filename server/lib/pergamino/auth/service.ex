defmodule Pergamino.Auth.Service do
  alias Pergamino.Domain.Email

  @spec create_login_link(String.t()) :: {:ok, String.t()} | {:error, any()}
  def create_login_link(email) do
    with {:ok, _email} <- Email.create(email) do
      {:ok, :not_implemented}
    else
      {:error, _} = error -> error
    end
  end

  @spec register_device(String.t(), String.t()) :: {:ok, String.t()} | {:error, any()}
  def register_device(_token, _public_key) do
    {:error, :not_implemented}
  end
end
