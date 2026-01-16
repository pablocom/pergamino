defmodule Pergamino.ConnCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  using do
    quote do
      @endpoint Pergamino.Web.Endpoint

      use Pergamino, :verified_routes

      import Plug.Conn
      import Phoenix.ConnTest
      import Pergamino.ConnCase
      import Pergamino.ProblemDetailsHelpers
    end
  end

  setup _tags do
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
