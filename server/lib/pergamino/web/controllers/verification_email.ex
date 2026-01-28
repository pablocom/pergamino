defmodule Pergamino.Web.Controllers.VerificationEmail do
  use Pergamino, :controller

  alias Pergamino.Infrastructure.Auth.OAuth2Flow
  alias Pergamino.Web.Validation.Validator

  action_fallback(Pergamino.Web.ErrorHandler)

  @validation_schema [
    email: [:required, {:type, :string}],
    code_challenge: [:required, {:type, :string}]
  ]

  def create(conn, params) do
    with {:ok, validated_params} <- Validator.validate(params, @validation_schema),
         :ok <- OAuth2Flow.initiate(validated_params) do
      send_resp(conn, 202, "")
    end
  end
end
