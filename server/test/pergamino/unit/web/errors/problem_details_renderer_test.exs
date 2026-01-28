defmodule Pergamino.Unit.Web.Errors.ProblemDetailsRendererTest do
  use ExUnit.Case, async: true

  alias Pergamino.Web.Errors.ProblemDetailsRenderer
  alias Pergamino.Web.Errors.ValidationError
  alias Pergamino.Web.Errors.AuthenticationError
  alias Pergamino.Web.Errors.InfrastructureError
  alias Pergamino.Web.Errors.UnknownError

  describe "render/1 for ValidationError" do
    test "renders required field error" do
      error = ValidationError.required(:email)
      rendered = ProblemDetailsRenderer.render(error)

      assert %{
               type: "https://pergamino.app/errors/validation/required-email",
               status: 400,
               detail: "Email is required",
               extensions: %{
                 field: :email,
                 code: :required
               }
             } = rendered
    end

    test "renders invalid format error" do
      error = ValidationError.invalid_format(:email, "must be a valid email address")
      rendered = ProblemDetailsRenderer.render(error)

      assert %{
               type: "https://pergamino.app/errors/validation/invalid_format-email",
               status: 400,
               detail: "must be a valid email address",
               extensions: %{
                 field: :email,
                 code: :invalid_format
               }
             } = rendered
    end

    test "renders too_long error with details" do
      error = ValidationError.too_long(:email, 255)
      rendered = ProblemDetailsRenderer.render(error)

      assert %{
               type: "https://pergamino.app/errors/validation/too_long-email",
               status: 400,
               detail: "Email must not exceed 255 characters",
               extensions: %{
                 field: :email,
                 code: :too_long,
                 max_length: 255
               }
             } = rendered
    end

    test "renders too_short error with details" do
      error = ValidationError.too_short(:code_verifier, 43)
      rendered = ProblemDetailsRenderer.render(error)

      assert %{
               type: "https://pergamino.app/errors/validation/too_short-code_verifier",
               status: 400,
               detail: "Code Verifier must be at least 43 characters",
               extensions: %{
                 field: :code_verifier,
                 code: :too_short,
                 min_length: 43
               }
             } = rendered
    end
  end

  describe "render/1 for AuthenticationError" do
    test "renders invalid authorization code error with 401 status" do
      error = AuthenticationError.invalid_authorization_code()
      rendered = ProblemDetailsRenderer.render(error)

      assert %{
               type: "https://pergamino.app/errors/authentication/invalid_authorization_code",
               status: 401,
               detail: "Invalid or expired authorization code",
               extensions: %{
                 code: :invalid_authorization_code
               }
             } = rendered
    end

    test "renders invalid refresh token error with 401 status" do
      error = AuthenticationError.invalid_refresh_token()
      rendered = ProblemDetailsRenderer.render(error)

      assert %{
               type: "https://pergamino.app/errors/authentication/invalid_refresh_token",
               status: 401,
               detail: "Invalid or expired refresh token",
               extensions: %{
                 code: :invalid_refresh_token
               }
             } = rendered
    end
  end

  describe "render/1 for InfrastructureError" do
    test "renders service unavailable error without exposing service details" do
      error = InfrastructureError.service_unavailable(:redis)
      rendered = ProblemDetailsRenderer.render(error)

      assert %{
               type: "https://pergamino.app/errors/service-unavailable",
               status: 503,
               detail: "Service temporarily unavailable",
               extensions: %{
                 code: :service_unavailable
               }
             } = rendered

      refute Map.has_key?(rendered.extensions, :service)
    end

    test "hides infrastructure details for all services" do
      for service <- [:redis, :dynamodb, :email] do
        error = InfrastructureError.service_unavailable(service)
        rendered = ProblemDetailsRenderer.render(error)

        refute Map.has_key?(rendered.extensions, :service),
               "Service #{service} should not be exposed in extensions"
      end
    end
  end

  describe "render/1 for UnknownError" do
    test "renders internal server error" do
      error = UnknownError.internal_server_error()
      rendered = ProblemDetailsRenderer.render(error)

      assert %{
               type: "https://pergamino.app/errors/internal-server-error",
               status: 500,
               detail: "An unexpected error occurred",
               extensions: %{
                 code: :internal_server_error
               }
             } = rendered
    end
  end
end
