defmodule Pergamino.Web.Schemas.VerificationEmailRequest do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :email, :string
    field :code_challenge, :string
  end

  @type validated :: %{
          email: String.t(),
          code_challenge: String.t()
        }

  @spec validate(map()) :: {:ok, validated()} | {:error, atom()}
  def validate(params) do
    changeset =
      %__MODULE__{}
      |> cast(params, [:email, :code_challenge])
      |> validate_required_field(:email, :missing_email)
      |> validate_required_field(:code_challenge, :missing_code_challenge)
      |> validate_email_format()

    case apply_action(changeset, :validate) do
      {:ok, validated} ->
        {:ok,
         %{
           email: validated.email,
           code_challenge: validated.code_challenge
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

  defp validate_email_format(changeset) do
    email = get_field(changeset, :email)

    if is_nil(email) || email == "" do
      changeset
    else
      if String.contains?(email, "@") do
        changeset
      else
        add_error(changeset, :email, "", error_code: :invalid_email)
      end
    end
  end

  defp extract_first_error(changeset) do
    {_field, {_message, opts}} = Enum.at(changeset.errors, 0)
    Keyword.get(opts, :error_code, :validation_error)
  end
end
