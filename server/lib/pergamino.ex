defmodule Pergamino.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Pergamino.Web.Telemetry,
      {DNSCluster, query: Application.get_env(:pergamino, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Pergamino.PubSub},
      {Finch, name: Pergamino.Finch},
      Pergamino.Infrastructure.Auth.TokenGenerator.SignerLoader,
      Pergamino.Web.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Pergamino.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    Pergamino.Web.Endpoint.config_change(changed, removed)
    :ok
  end
end

defmodule Pergamino do
  def static_paths, do: []

  def router do
    quote do
      use Phoenix.Router, helpers: false

      import Plug.Conn
      import Phoenix.Controller
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  def controller do
    quote do
      use Phoenix.Controller, formats: [:json]

      import Plug.Conn

      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: Pergamino.Web.Endpoint,
        router: Pergamino.Web.Router,
        statics: Pergamino.static_paths()
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
