defmodule Pergamino.Web.Errors.InfrastructureError do
  @type service :: :redis | :dynamodb | :email
  @type code :: :service_unavailable

  @type t :: %__MODULE__{
          service: service(),
          code: code(),
          message: String.t(),
          details: map()
        }

  defstruct [:service, :code, :message, :details]

  @spec service_unavailable(service()) :: t()
  def service_unavailable(service) do
    %__MODULE__{
      service: service,
      code: :service_unavailable,
      message: "Service temporarily unavailable",
      details: %{}
    }
  end
end
