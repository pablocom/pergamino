defmodule Pergamino.ChannelCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      @endpoint Pergamino.Web.Endpoint
      use Pergamino, :verified_routes
      import Phoenix.ChannelTest
      import Pergamino.ChannelCase
    end
  end

  setup _tags do
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
