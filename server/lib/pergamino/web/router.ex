defmodule Pergamino.Web.Router do
  use Pergamino, :router

  pipeline :api do
    plug(:accepts, ["json"])
  end

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  scope "/api", Pergamino.Web do
    pipe_through(:api)

    post("/auth/login", Controllers.Auth, :login)
  end

  if Application.compile_env(:pergamino, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through([:browser])
      live_dashboard("/dashboard", metrics: Pergamino.Web.Telemetry)
    end
  end
end
