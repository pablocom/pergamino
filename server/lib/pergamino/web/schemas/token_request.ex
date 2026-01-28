defmodule Pergamino.Web.Schemas.TokenRequest do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :code, :string
    field :code_verifier, :string
  end

  @type validated :: %{
          code: String.t(),
          code_verifier: String.t()
        }

  @spec validate(map()) :: {:ok, validated()} | {:error, atom()}
  def validate(params) do
    changeset =
      %__MODULE__{}
      |> cast(params, [:code, :code_verifier])
      |> validate_required_field(:code, :missing_code)
      |> validate_required_field(:code_verifier, :missing_code_verifier)

    case apply_action(changeset, :validate) do
      {:ok, validated} ->
        {:ok,
         %{
           code: validated.code,
           code_verifier: validated.code_verifier
         }}

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
