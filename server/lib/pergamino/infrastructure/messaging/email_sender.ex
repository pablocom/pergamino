defmodule Pergamino.Infrastructure.Messaging.EmailSender do
  @behaviour Pergamino.Infrastructure.Messaging.EmailSenderBehaviour

  use Swoosh.Mailer, otp_app: :pergamino
  import Swoosh.Email

  alias Pergamino.Domain.EmailAddress

  @spec send_verification_email(EmailAddress.t(), String.t()) ::
          {:ok, term()} | {:error, :email_delivery_failed}
  def send_verification_email(%EmailAddress{} = recipient, deeplink) do
    case recipient
         |> build_verification_email(deeplink)
         |> deliver() do
      {:ok, result} ->
        {:ok, result}

      {:error, _reason} ->
        {:error, :email_delivery_failed}
    end
  end

  @spec build_verification_email(EmailAddress.t(), String.t()) :: Swoosh.Email.t()
  defp build_verification_email(%EmailAddress{} = recipient, deeplink) do
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
