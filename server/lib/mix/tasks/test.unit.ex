defmodule Mix.Tasks.Test.Unit do
  use Mix.Task

  @shortdoc "Runs unit tests only"
  @moduledoc """
  Runs only unit tests from test/pergamino/unit directory.

  Unit tests are fast, isolated tests with no external dependencies.
  They test business logic in isolation using mocked dependencies.

  ## Example

      mix test.unit
  """

  @impl Mix.Task
  def run(args) do
    Application.put_env(:pergamino, :tests, skip_containers: true)
    Mix.Task.run("test", ["test/pergamino/unit" | args])
  end
end
