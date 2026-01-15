defmodule PergaminoWeb.ConnCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  using do
    quote do
      @endpoint PergaminoWeb.Endpoint

      use PergaminoWeb, :verified_routes

      import Plug.Conn
      import Phoenix.ConnTest
      import PergaminoWeb.ConnCase
    end
  end

  setup _tags do
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
