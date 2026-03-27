defmodule Pergamino.Domain.MessageText do
  @type t :: %__MODULE__{content: String.t()}
  defstruct content: nil

  @max_length 1500

  @spec create(String.t()) :: {:ok, t()} | {:error, :invalid_message_text}
  def create(text) when is_binary(text) do
    cond do
      String.length(text) == 0 -> {:error, :invalid_message_text}
      String.length(text) > @max_length -> {:error, :invalid_message_text}
      true -> {:ok, %__MODULE__{content: text}}
    end
  end

  def create(_), do: {:error, :invalid_message_text}
end
