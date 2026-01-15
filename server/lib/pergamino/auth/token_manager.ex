defmodule Pergamino.Auth.TokenManager do
  @callback generate(email :: String.t()) :: {:ok, String.t()} | {:error, any()}
  @callback verify(token :: String.t()) :: {:ok, map()} | {:error, any()}
end
