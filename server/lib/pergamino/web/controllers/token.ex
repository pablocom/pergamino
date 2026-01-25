defmodule Pergamino.Web.Controllers.Token do
  use Pergamino, :controller

  alias Pergamino.Infrastructure.Auth.OAuth2Flow

  action_fallback(Pergamino.Web.ErrorHandler)

  @spec exchange(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def exchange(conn, params) do
    with {:ok, exchange_params} <- extract_exchange_params(params),
         {:ok, token_response} <- OAuth2Flow.exchange_authorization_code(exchange_params) do
      json(conn, token_response)
    end
  end

  @spec refresh(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def refresh(conn, params) do
    with {:ok, refresh_token} <- fetch_refresh_token(params),
         {:ok, token_response} <- OAuth2Flow.refresh_access_token(refresh_token) do
      json(conn, token_response)
    end
  end

  defp extract_exchange_params(params) do
    with {:ok, code} <- fetch_code(params),
         {:ok, code_verifier} <- fetch_code_verifier(params) do
      {:ok, %{code: code, code_verifier: code_verifier}}
    end
  end

  defp fetch_code(%{"code" => value}) when is_binary(value) and byte_size(value) > 0,
    do: {:ok, value}

  defp fetch_code(_), do: {:error, :missing_code}

  defp fetch_code_verifier(%{"code_verifier" => value})
       when is_binary(value) and byte_size(value) > 0,
       do: {:ok, value}

  defp fetch_code_verifier(_), do: {:error, :missing_code_verifier}

  defp fetch_refresh_token(%{"refresh_token" => value})
       when is_binary(value) and byte_size(value) > 0,
       do: {:ok, value}

  defp fetch_refresh_token(_), do: {:error, :missing_refresh_token}
end
