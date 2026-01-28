defmodule Pergamino.Web.Errors.ValidationError do
  @type code :: :required | :invalid_format | :too_long | :too_short

  @type t :: %__MODULE__{
          field: atom(),
          code: code(),
          message: String.t(),
          details: map()
        }

  defstruct [:field, :code, :message, :details]

  @spec required(atom()) :: t()
  def required(field) do
    %__MODULE__{
      field: field,
      code: :required,
      message: humanize_field(field) <> " is required",
      details: %{}
    }
  end

  @spec invalid_format(atom(), String.t()) :: t()
  def invalid_format(field, message) do
    %__MODULE__{
      field: field,
      code: :invalid_format,
      message: message,
      details: %{}
    }
  end

  @spec too_long(atom(), pos_integer()) :: t()
  def too_long(field, max_length) do
    %__MODULE__{
      field: field,
      code: :too_long,
      message: "#{humanize_field(field)} must not exceed #{max_length} characters",
      details: %{max_length: max_length}
    }
  end

  @spec too_short(atom(), pos_integer()) :: t()
  def too_short(field, min_length) do
    %__MODULE__{
      field: field,
      code: :too_short,
      message: "#{humanize_field(field)} must be at least #{min_length} characters",
      details: %{min_length: min_length}
    }
  end

  defp humanize_field(field) do
    field
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map_join(" ", &String.capitalize/1)
  end
end
