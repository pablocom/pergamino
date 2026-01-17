defmodule Pergamino.Auth.DeviceBindingEmail do
  import Swoosh.Email

  @from_address "noreply@pergamino.dev"
  @subject "Complete Your Device Setup"

  @spec build(String.t(), String.t()) :: Swoosh.Email.t()
  def build(recipient_email, deeplink) do
    body = """
    Click the link below to complete device binding:

    #{deeplink}
    """

    new()
    |> to(recipient_email)
    |> from(@from_address)
    |> subject(@subject)
    |> text_body(body)
  end
end
