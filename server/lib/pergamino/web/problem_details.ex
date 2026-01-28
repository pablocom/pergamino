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
          | :invalid_email
          | :invalid_email_format
          | :missing_code_challenge
          | :missing_code_challenge_method
          | :invalid_pkce_parameters
          | :missing_code
          | :missing_code_verifier
          | :invalid_authorization_code
          | :missing_refresh_token
          | :invalid_refresh_token
          | :token_generation_failed
          | :redis_unavailable
          | :dynamodb_unavailable
          | :email_delivery_failed
          | :internal_server_error
          | :service_unavailable
          | :not_implemented

  @spec build(error_code(), String.t()) :: {:ok, t()}
  def build(error_code, instance) do
    problem_code = map_error_code(error_code)

    problem_details =
      problem_details_for(problem_code)
      |> Map.put(:instance, instance)

    {:ok, problem_details}
  end

  defp map_error_code(error_code) do
    case error_code do
      :missing_email -> :missing_email
      :invalid_email -> :invalid_email_format
      :missing_code_challenge -> :missing_code_challenge
      :missing_code_challenge_method -> :missing_code_challenge_method
      :invalid_pkce_parameters -> :invalid_pkce_parameters
      :missing_code -> :missing_code
      :missing_code_verifier -> :missing_code_verifier
      :invalid_authorization_code -> :invalid_authorization_code
      :missing_refresh_token -> :missing_refresh_token
      :invalid_refresh_token -> :invalid_refresh_token
      :not_implemented -> :not_implemented
      _ -> :internal_server_error
    end
  end

  defp problem_details_for(:missing_email) do
    %{
      type: "https://pergamino.app/errors/missing-email",
      title: "Validation Error",
      status: 400,
      detail: "Email parameter is required",
      extensions: %{
        error_code: "INVALID_EMAIL"
      }
    }
  end

  defp problem_details_for(:invalid_email_format) do
    %{
      type: "https://pergamino.app/errors/invalid-email-format",
      title: "Validation Error",
      status: 400,
      detail: "Email format is invalid",
      extensions: %{
        error_code: "INVALID_EMAIL"
      }
    }
  end

  defp problem_details_for(:missing_code_challenge) do
    %{
      type: "https://pergamino.app/errors/missing-code-challenge",
      title: "Validation Error",
      status: 400,
      detail: "Code challenge parameter is required",
      extensions: %{
        error_code: "MISSING_CODE_CHALLENGE"
      }
    }
  end

  defp problem_details_for(:missing_code_challenge_method) do
    %{
      type: "https://pergamino.app/errors/missing-code-challenge-method",
      title: "Validation Error",
      status: 400,
      detail: "Code challenge method parameter is required",
      extensions: %{
        error_code: "MISSING_CODE_CHALLENGE_METHOD"
      }
    }
  end

  defp problem_details_for(:invalid_pkce_parameters) do
    %{
      type: "https://pergamino.app/errors/invalid-pkce-parameters",
      title: "Validation Error",
      status: 400,
      detail: "Invalid PKCE parameters",
      extensions: %{
        error_code: "INVALID_PKCE_PARAMETERS"
      }
    }
  end

  defp problem_details_for(:missing_code) do
    %{
      type: "https://pergamino.app/errors/missing-code",
      title: "Validation Error",
      status: 400,
      detail: "Authorization code parameter is required",
      extensions: %{
        error_code: "MISSING_CODE"
      }
    }
  end

  defp problem_details_for(:missing_code_verifier) do
    %{
      type: "https://pergamino.app/errors/missing-code-verifier",
      title: "Validation Error",
      status: 400,
      detail: "Code verifier parameter is required",
      extensions: %{
        error_code: "MISSING_CODE_VERIFIER"
      }
    }
  end

  defp problem_details_for(:invalid_authorization_code) do
    %{
      type: "https://pergamino.app/errors/invalid-authorization-code",
      title: "Authentication Error",
      status: 400,
      detail: "Invalid or expired authorization code",
      extensions: %{
        error_code: "INVALID_AUTHORIZATION_CODE"
      }
    }
  end

  defp problem_details_for(:missing_refresh_token) do
    %{
      type: "https://pergamino.app/errors/missing-refresh-token",
      title: "Validation Error",
      status: 400,
      detail: "Refresh token parameter is required",
      extensions: %{
        error_code: "MISSING_REFRESH_TOKEN"
      }
    }
  end

  defp problem_details_for(:invalid_refresh_token) do
    %{
      type: "https://pergamino.app/errors/invalid-refresh-token",
      title: "Authentication Error",
      status: 400,
      detail: "Invalid or expired refresh token",
      extensions: %{
        error_code: "INVALID_REFRESH_TOKEN"
      }
    }
  end

  defp problem_details_for(:internal_server_error) do
    %{
      type: "https://pergamino.app/errors/internal-server-error",
      title: "Internal Server Error",
      status: 500,
      detail: "An unexpected error occurred",
      extensions: %{}
    }
  end

  defp problem_details_for(:not_implemented) do
    %{
      type: "https://pergamino.app/errors/not-implemented",
      title: "Not Implemented",
      status: 501,
      detail: "This feature is not yet implemented",
      extensions: %{}
    }
  end
end
