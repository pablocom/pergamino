defmodule Pergamino.Infrastructure.Auth.RefreshTokenStoreBehaviour do
  alias Pergamino.Domain.EmailAddress

  @callback store(
              token :: String.t(),
              expires_at :: DateTime.t(),
              email :: EmailAddress.t()
            ) :: :ok | {:error, :dynamodb_unavailable}

  @callback retrieve_and_delete(String.t()) ::
              {:ok, String.t()}
              | {:error, :token_not_found | :dynamodb_unavailable}
end
