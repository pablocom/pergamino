defmodule Pergamino.Infrastructure.Messaging.EmailSender do
  use Swoosh.Mailer, otp_app: :pergamino
  import Swoosh.Email

  alias Pergamino.Domain.EmailAddress

  @spec send_device_binding_email(EmailAddress.t(), String.t()) ::
          {:ok, term()} | {:error, term()}
  def send_device_binding_email(%EmailAddress{} = recipient, deeplink) do
    recipient
    |> build_device_binding_email(deeplink)
    |> deliver()
  end

  @spec build_device_binding_email(EmailAddress.t(), String.t()) :: Swoosh.Email.t()
  defp build_device_binding_email(%EmailAddress{} = recipient, deeplink) do
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
