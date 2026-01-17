defmodule Pergamino.Mailer do
  use Swoosh.Mailer, otp_app: :pergamino
  import Swoosh.Email

  alias Pergamino.Domain.Email

  @type device_binding_email_type ::
          {:device_binding, recipient :: Email.t(), deeplink :: String.t()}

  @spec send(device_binding_email_type()) :: {:ok, term()} | {:error, term()}
  def send(email) do
    email
    |> build_swoosh_email()
    |> deliver()
  end

  @spec build_swoosh_email(device_binding_email_type()) :: Swoosh.Email.t()
  defp build_swoosh_email({:device_binding, recipient, deeplink}) do
    body = """
    Click the link below to complete device binding:

    #{deeplink}
    """

    new()
    |> to(recipient.address)
    |> from("noreply@pergamino.dev")
    |> subject("Complete Your Device Setup")
    |> text_body(body)
  end
end
