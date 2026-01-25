defmodule Pergamino.Infrastructure.Auth.AuthorizationCodeStoreBehaviour do
  alias Pergamino.Domain.EmailAddress

  @callback store(
              code :: String.t(),
              expires_at :: DateTime.t(),
              email :: EmailAddress.t(),
              challenge :: String.t()
            ) :: :ok | {:error, :redis_unavailable}

  @callback retrieve_and_delete(String.t()) ::
              {:ok, String.t(), String.t()}
              | {:error, :code_not_found | :redis_unavailable}
end
