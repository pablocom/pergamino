defmodule Mix.Tasks.Test.Component do
  use Mix.Task

  @shortdoc "Runs component tests only"
  @moduledoc """
  Runs only component tests from test/component directory.

  Component tests verify the full HTTP stack with real infrastructure through controller endpoints.

  ## Example

      mix test.component
  """

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("test", ["test/component" | args])
  end
end
