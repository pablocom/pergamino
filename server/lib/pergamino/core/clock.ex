defmodule Pergamino.Core.Clock do
  @moduledoc false

  @callback utc_now() :: DateTime.t()

  @spec utc_now() :: DateTime.t()
  def utc_now do
    adapter = impl()

    if adapter == __MODULE__ do
      DateTime.utc_now()
    else
      adapter.utc_now()
    end
  end

  defp impl do
    Application.get_env(:pergamino, :clock_adapter, __MODULE__)
  end
end
