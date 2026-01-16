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
          | :internal_server_error
          | :not_implemented

  @spec build(error_code(), String.t()) :: t()
  def build(error_code, instance) do
    base_problem(error_code)
    |> Map.put(:instance, instance)
  end

  defp base_problem(:missing_email) do
    %{
      type: "https://pergamino.dev/problems/validation-error",
      title: "Validation Error",
      status: 400,
      detail: "Email parameter is required",
      extensions: %{
        error_code: "INVALID_EMAIL"
      }
    }
  end

  defp base_problem(:invalid_email_format) do
    %{
      type: "https://pergamino.dev/problems/validation-error",
      title: "Validation Error",
      status: 400,
      detail: "Email format is invalid",
      extensions: %{
        error_code: "INVALID_EMAIL"
      }
    }
  end

  defp base_problem(:internal_server_error) do
    %{
      type: "https://pergamino.dev/problems/internal-error",
      title: "Internal Server Error",
      status: 500,
      detail: "An unexpected error occurred",
      extensions: %{}
    }
  end

  defp base_problem(:not_implemented) do
    %{
      type: "https://pergamino.dev/problems/not-implemented",
      title: "Not Implemented",
      status: 501,
      detail: "This feature is not yet implemented",
      extensions: %{}
    }
  end
end
