defprotocol Pergamino.Web.Errors.ProblemDetailsRenderer do
  @type problem_details :: %{
          type: String.t(),
          status: integer(),
          detail: String.t(),
          extensions: map()
        }

  @spec render(t()) :: problem_details()
  def render(error)
end

defimpl Pergamino.Web.Errors.ProblemDetailsRenderer,
  for: Pergamino.Web.Errors.ValidationError do
  def render(%{field: field, code: code, message: message, details: details}) do
    %{
      type: "https://pergamino.app/errors/validation/#{code}-#{field}",
      status: 400,
      detail: message,
      extensions: Map.merge(%{field: field, code: code}, details)
    }
  end
end

defimpl Pergamino.Web.Errors.ProblemDetailsRenderer,
  for: Pergamino.Web.Errors.AuthenticationError do
  def render(%{code: code, message: message}) do
    %{
      type: "https://pergamino.app/errors/authentication/#{code}",
      status: 401,
      detail: message,
      extensions: %{code: code}
    }
  end
end

defimpl Pergamino.Web.Errors.ProblemDetailsRenderer,
  for: Pergamino.Web.Errors.InfrastructureError do
  def render(%{message: message}) do
    %{
      type: "https://pergamino.app/errors/service-unavailable",
      status: 503,
      detail: message,
      extensions: %{code: :service_unavailable}
    }
  end
end

defimpl Pergamino.Web.Errors.ProblemDetailsRenderer,
  for: Pergamino.Web.Errors.UnknownError do
  def render(%{message: message}) do
    %{
      type: "https://pergamino.app/errors/internal-server-error",
      status: 500,
      detail: message,
      extensions: %{code: :internal_server_error}
    }
  end
end
