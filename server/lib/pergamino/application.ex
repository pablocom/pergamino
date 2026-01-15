defmodule Pergamino.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      PergaminoWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:pergamino, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Pergamino.PubSub},
      # Start a worker by calling: Pergamino.Worker.start_link(arg)
      # {Pergamino.Worker, arg},
      # Start to serve requests, typically the last entry
      PergaminoWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Pergamino.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PergaminoWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
