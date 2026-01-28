defmodule Pergamino.Web.Errors.AuthenticationError do
  @type code :: :invalid_authorization_code | :invalid_refresh_token

  @type t :: %__MODULE__{
          code: code(),
          message: String.t(),
          details: map()
        }

  defstruct [:code, :message, :details]

  @spec invalid_authorization_code() :: t()
  def invalid_authorization_code do
    %__MODULE__{
      code: :invalid_authorization_code,
      message: "Invalid or expired authorization code",
      details: %{}
    }
  end

  @spec invalid_refresh_token() :: t()
  def invalid_refresh_token do
    %__MODULE__{
      code: :invalid_refresh_token,
      message: "Invalid or expired refresh token",
      details: %{}
    }
  end
end
