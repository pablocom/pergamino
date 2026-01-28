defmodule Pergamino.Web.Validation.Validator do
  alias Pergamino.Web.Errors.ValidationError

  @type params :: map()
  @type field_name :: atom()
  @type validator ::
          :required
          | {:type, :string}
          | {:max_length, pos_integer()}
          | {:min_length, pos_integer()}
          | (any() -> :ok | {:error, String.t() | atom()})
  @type schema :: [{field_name(), [validator()]}]

  @spec validate(params(), schema()) ::
          {:ok, map()} | {:error, [ValidationError.t()]}
  def validate(params, schema) do
    {validated, errors} =
      Enum.reduce(schema, {%{}, []}, fn {field, validators}, {acc_validated, acc_errors} ->
        field_string = Atom.to_string(field)
        value = Map.get(params, field_string)

        case validate_field(field, value, validators) do
          {:ok, validated_value} ->
            {Map.put(acc_validated, field, validated_value), acc_errors}

          {:error, error} ->
            {acc_validated, [error | acc_errors]}

          :skip ->
            {acc_validated, acc_errors}
        end
      end)

    case errors do
      [] -> {:ok, validated}
      errors -> {:error, Enum.reverse(errors)}
    end
  end

  defp validate_field(field, value, validators) do
    case has_required_validator?(validators) do
      true -> validate_required_field(field, value, validators)
      false -> validate_optional_field(field, value, validators)
    end
  end

  defp validate_required_field(field, value, validators) do
    Enum.reduce_while(validators, {:ok, value}, fn validator, {:ok, current_value} ->
      case apply_validator(field, current_value, validator) do
        :ok -> {:cont, {:ok, current_value}}
        {:error, error} -> {:halt, {:error, error}}
      end
    end)
  end

  defp validate_optional_field(_field, nil, _validators), do: :skip
  defp validate_optional_field(_field, value, _validators) when value == "", do: :skip

  defp validate_optional_field(field, value, validators) do
    non_required_validators = Enum.reject(validators, &(&1 == :required))

    Enum.reduce_while(non_required_validators, {:ok, value}, fn validator, {:ok, current_value} ->
      case apply_validator(field, current_value, validator) do
        :ok -> {:cont, {:ok, current_value}}
        {:error, error} -> {:halt, {:error, error}}
      end
    end)
  end

  defp has_required_validator?(validators) do
    Enum.any?(validators, &(&1 == :required))
  end

  defp apply_validator(field, value, :required) do
    if present?(value) do
      :ok
    else
      {:error, ValidationError.required(field)}
    end
  end

  defp apply_validator(field, value, {:type, :string}) do
    if is_binary(value) do
      :ok
    else
      {:error, ValidationError.invalid_format(field, "#{humanize_field(field)} must be a string")}
    end
  end

  defp apply_validator(field, value, {:max_length, max}) when is_binary(value) do
    if String.length(value) <= max do
      :ok
    else
      {:error, ValidationError.too_long(field, max)}
    end
  end

  defp apply_validator(field, value, {:min_length, min}) when is_binary(value) do
    if String.length(value) >= min do
      :ok
    else
      {:error, ValidationError.too_short(field, min)}
    end
  end

  defp apply_validator(field, value, custom_validator) when is_function(custom_validator, 1) do
    case custom_validator.(value) do
      :ok ->
        :ok

      {:error, message} when is_binary(message) ->
        {:error, ValidationError.invalid_format(field, message)}

      {:error, reason} when is_atom(reason) ->
        {:error, ValidationError.invalid_format(field, "#{humanize_field(field)} is invalid")}
    end
  end

  defp present?(nil), do: false
  defp present?(""), do: false

  defp present?(value) when is_binary(value) do
    String.trim(value) != ""
  end

  defp present?(_), do: true

  defp humanize_field(field) do
    field
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map_join(" ", &String.capitalize/1)
  end
end
