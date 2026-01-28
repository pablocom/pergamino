defmodule Pergamino.Web.Validation.CommonValidators do
  @email_regex ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/
  @pkce_verifier_regex ~r/^[A-Za-z0-9_-]{43,128}$/

  @spec email_format() :: (String.t() -> :ok | {:error, String.t()})
  def email_format do
    fn value ->
      if Regex.match?(@email_regex, value) do
        :ok
      else
        {:error, "Email format is invalid"}
      end
    end
  end

  @spec pkce_verifier_format() :: (String.t() -> :ok | {:error, String.t()})
  def pkce_verifier_format do
    fn value ->
      cond do
        byte_size(value) < 43 ->
          {:error, "Code verifier must be at least 43 characters"}

        byte_size(value) > 128 ->
          {:error, "Code verifier must not exceed 128 characters"}

        not Regex.match?(@pkce_verifier_regex, value) ->
          {:error, "Code verifier must be URL-safe base64 without padding"}

        true ->
          :ok
      end
    end
  end
end
