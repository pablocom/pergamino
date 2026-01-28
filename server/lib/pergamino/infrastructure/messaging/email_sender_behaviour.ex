defmodule Pergamino.Infrastructure.Messaging.EmailSenderBehaviour do
  alias Pergamino.Domain.EmailAddress

  @callback send_verification_email(EmailAddress.t(), String.t()) ::
              {:ok, term()} | {:error, term()}
end
