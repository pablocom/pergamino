defmodule Mix.Tasks.Test.Integration do
  use Mix.Task

  @shortdoc "Runs integration tests only"
  @moduledoc """
  Runs only integration tests from test/pergamino/integration directory.

  Integration tests verify narrow integrations with external dependencies
  like Redis and email services using real connections.

  ## Example

      mix test.integration
  """

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("test", ["test/pergamino/integration" | args])
  end
end
