defmodule Pergamino.Web.ProblemDetails do
  @type t :: %{
          type: String.t(),
          title: String.t(),
          status: integer(),
          detail: String.t(),
          instance: String.t(),
          extensions: map()
        }

  @type error_code ::
          :missing_email
          | :invalid_email_format

  @spec build(error_code(), String.t()) :: t()
  def build(error_code, instance) do
    case error_code do
      :missing_email ->
        %{
          type: "https://pergamino.dev/problems/validation-error",
          title: "Validation Error",
          status: 400,
          detail: "Email parameter is required",
          instance: instance,
          extensions: %{
            error_code: "INVALID_EMAIL"
          }
        }

      :invalid_email_format ->
        %{
          type: "https://pergamino.dev/problems/validation-error",
          title: "Validation Error",
          status: 400,
          detail: "Email format is invalid",
          instance: instance,
          extensions: %{
            error_code: "INVALID_EMAIL"
          }
        }
    end
  end
end
