defmodule Pergamino.ProblemDetailsHelpers do
  import ExUnit.Assertions

  @spec assert_problem_details(Plug.Conn.t(), integer(), keyword()) :: map()
  def assert_problem_details(conn, expected_status, expectations \\ []) do
    response = Phoenix.ConnTest.json_response(conn, expected_status)

    assert_map_contains(response, expectations)

    response
  end

  @spec assert_validation_error(Plug.Conn.t(), String.t(), String.t()) :: map()
  def assert_validation_error(conn, expected_detail, expected_instance) do
    assert_problem_details(conn, 400,
      type: "validation-error",
      title: "Validation Error",
      status: 400,
      detail: expected_detail,
      instance: expected_instance,
      extensions: %{"error_code" => "INVALID_EMAIL"}
    )
  end

  @spec assert_internal_error(Plug.Conn.t(), String.t()) :: map()
  def assert_internal_error(conn, expected_instance) do
    assert_problem_details(conn, 500,
      type: "internal-error",
      title: "Internal Server Error",
      status: 500,
      detail: "An unexpected error occurred",
      instance: expected_instance
    )
  end

  defp assert_map_contains(map, []), do: map

  defp assert_map_contains(map, [{key, expected_value} | rest]) do
    key_string = to_string(key)
    actual_value = Map.get(map, key_string)

    case expected_value do
      expected_map when is_map(expected_map) ->
        assert is_map(actual_value),
               "Expected #{key_string} to be a map, got: #{inspect(actual_value)}"

        assert_map_contains(actual_value, Map.to_list(expected_map))

      expected_list when is_list(expected_list) ->
        assert_map_contains(map, expected_list)

      _ ->
        assert actual_value == expected_value,
               "Expected #{key_string} to be #{inspect(expected_value)}, got: #{inspect(actual_value)}"
    end

    assert_map_contains(map, rest)
  end
end
