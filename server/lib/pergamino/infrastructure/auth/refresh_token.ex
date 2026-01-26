defmodule Pergamino.Infrastructure.Auth.RefreshToken do
  alias Pergamino.Core.Clock

  @token_length 32
  @expiration_seconds 15_552_000

  @spec generate() :: {token :: String.t(), expires_at :: DateTime.t()}
  def generate do
    token = generate_random_token()
    expires_at = expiration_time()
    {token, expires_at}
  end

  defp generate_random_token do
    :crypto.strong_rand_bytes(@token_length)
    |> Base.url_encode64(padding: false)
  end

  defp expiration_time do
    Clock.utc_now()
    |> DateTime.add(@expiration_seconds, :second)
  end
end
