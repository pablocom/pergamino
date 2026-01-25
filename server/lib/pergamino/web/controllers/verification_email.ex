defmodule Pergamino.Web.Controllers.VerificationEmail do
  use Pergamino, :controller

  alias Pergamino.Infrastructure.Auth.OAuth2Flow

  action_fallback(Pergamino.Web.ErrorHandler)

  def create(conn, params) do
    with {:ok, send_params} <- extract_params(params),
         :ok <- OAuth2Flow.initiate(send_params) do
      send_resp(conn, 202, "")
    end
  end

  defp extract_params(params) do
    with {:ok, email} <- fetch_email(params),
         {:ok, code_challenge} <- fetch_code_challenge(params) do
      {:ok,
       %{
         email: email,
         code_challenge: code_challenge
       }}
    end
  end

  defp fetch_email(%{"email" => value}) when is_binary(value) and byte_size(value) > 0,
    do: {:ok, value}

  defp fetch_email(_), do: {:error, :missing_email}

  defp fetch_code_challenge(%{"code_challenge" => value})
       when is_binary(value) and byte_size(value) > 0,
       do: {:ok, value}

  defp fetch_code_challenge(_), do: {:error, :missing_code_challenge}
end
