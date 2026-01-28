defmodule Pergamino.Web.Controllers.Token do
  use Pergamino, :controller

  alias Pergamino.Infrastructure.Auth.OAuth2Flow
  alias Pergamino.Web.Validation.Validator

  action_fallback(Pergamino.Web.ErrorHandler)

  @exchange_schema [
    code: [:required, {:type, :string}],
    code_verifier: [:required, {:type, :string}]
  ]

  @refresh_schema [
    refresh_token: [:required, {:type, :string}]
  ]

  @spec exchange(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def exchange(conn, params) do
    with {:ok, validated_params} <- Validator.validate(params, @exchange_schema),
         {:ok, token_response} <- OAuth2Flow.exchange_authorization_code(validated_params) do
      json(conn, token_response)
    end
  end

  @spec refresh(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def refresh(conn, params) do
    with {:ok, %{refresh_token: refresh_token}} <- Validator.validate(params, @refresh_schema),
         {:ok, token_response} <- OAuth2Flow.refresh_access_token(refresh_token) do
      json(conn, token_response)
    end
  end
end
