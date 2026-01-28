defmodule Pergamino.Web.Schemas.RefreshTokenRequest do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :refresh_token, :string
  end

  @type validated :: %{
          refresh_token: String.t()
        }

  @spec validate(map()) :: {:ok, validated()} | {:error, atom()}
  def validate(params) do
    changeset =
      %__MODULE__{}
      |> cast(params, [:refresh_token])
      |> validate_required_field(:refresh_token, :missing_refresh_token)

    case apply_action(changeset, :validate) do
      {:ok, validated} ->
        {:ok, %{refresh_token: validated.refresh_token}}

      {:error, changeset} ->
        {:error, extract_first_error(changeset)}
    end
  end

  defp validate_required_field(changeset, field, error_atom) do
    value = get_field(changeset, field)

    if is_nil(value) || value == "" do
      add_error(changeset, field, "", error_code: error_atom)
    else
      changeset
    end
  end

  defp extract_first_error(changeset) do
    {_field, {_message, opts}} = Enum.at(changeset.errors, 0)
    Keyword.get(opts, :error_code, :validation_error)
  end
end
