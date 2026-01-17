defmodule Pergamino.Domain.EmailAddress do
  @type t :: %__MODULE__{
          address: String.t()
        }

  defstruct address: nil

  @email_regex ~r/^[a-zA-Z0-9.!#$%&'*+\-\/=?^_`{|}~]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/

  @spec create(String.t()) :: {:ok, t()} | {:error, :invalid_email}
  def create(candidate) when is_binary(candidate) do
    cond do
      byte_size(candidate) == 0 ->
        {:error, :invalid_email}

      byte_size(candidate) > 255 ->
        {:error, :invalid_email}

      Regex.match?(@email_regex, candidate) ->
        {:ok, %__MODULE__{address: String.downcase(candidate)}}

      true ->
        {:error, :invalid_email}
    end
  end

  def create(_), do: {:error, :invalid_email}

  defimpl String.Chars, for: __MODULE__ do
    def to_string(email), do: email.address
  end
end
