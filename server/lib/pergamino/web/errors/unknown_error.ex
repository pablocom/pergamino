defmodule Pergamino.Web.Errors.UnknownError do
  @type code :: :internal_server_error

  @type t :: %__MODULE__{
          code: code(),
          message: String.t(),
          details: map()
        }

  defstruct [:code, :message, :details]

  @spec internal_server_error() :: t()
  def internal_server_error do
    %__MODULE__{
      code: :internal_server_error,
      message: "An unexpected error occurred",
      details: %{}
    }
  end
end
