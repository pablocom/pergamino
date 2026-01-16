defmodule Pergamino.Auth.Service do

  @spec create_login_link(String.t()) :: {:ok, String.t()} | {:error, any()}
  def create_login_link(_email) do

    {:error, :not_implemented}
  end

  @spec register_device(String.t(), String.t()) :: {:ok, String.t()} | {:error, any()}
  def register_device(_token, _public_key) do

    {:error, :not_implemented}
  end
end
