defmodule Pergamino.Web.Controllers.VerificationEmail do
  use Pergamino, :controller

  alias Pergamino.Infrastructure.Auth.OAuth2Flow
  alias Pergamino.Web.Schemas.VerificationEmailRequest

  action_fallback(Pergamino.Web.ErrorHandler)

  def create(conn, params) do
    with {:ok, validated_params} <- VerificationEmailRequest.validate(params),
         :ok <- OAuth2Flow.initiate(validated_params) do
      send_resp(conn, 202, "")
    end
  end
end
