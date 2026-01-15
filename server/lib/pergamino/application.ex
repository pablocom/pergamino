defmodule Pergamino.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      PergaminoWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:pergamino, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Pergamino.PubSub},
      PergaminoWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Pergamino.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    PergaminoWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
