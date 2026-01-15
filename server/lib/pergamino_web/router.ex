defmodule PergaminoWeb.Router do
  use PergaminoWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", PergaminoWeb do
    pipe_through :api

    post "/auth/login", AuthController, :login
  end

  if Application.compile_env(:pergamino, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: PergaminoWeb.Telemetry
    end
  end
end
