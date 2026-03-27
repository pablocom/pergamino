defmodule Pergamino.Domain.ConversationId do
  @type t :: %__MODULE__{value: String.t()}
  defstruct value: nil

  @uuid_v4_regex ~r/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i

  @spec create(String.t()) :: {:ok, t()} | {:error, :invalid_conversation_id}
  def create(id) when is_binary(id) do
    if Regex.match?(@uuid_v4_regex, id) do
      {:ok, %__MODULE__{value: id}}
    else
      {:error, :invalid_conversation_id}
    end
  end

  def create(_), do: {:error, :invalid_conversation_id}
end
