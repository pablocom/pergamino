defmodule Pergamino.Infrastructure.Auth.AuthorizationCodeGenerator do
  @code_length 32
  @expiration_seconds 300

  @spec generate() :: {code :: String.t(), expires_at :: DateTime.t()}
  def generate do
    code = generate_random_code()
    expires_at = expiration_time()
    {code, expires_at}
  end

  defp generate_random_code do
    :crypto.strong_rand_bytes(@code_length)
    |> Base.url_encode64(padding: false)
  end

  defp expiration_time do
    DateTime.utc_now()
    |> DateTime.add(@expiration_seconds, :second)
  end
end
