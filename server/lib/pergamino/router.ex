defmodule Pergamino.Router do
  use Pergamino, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", Pergamino do
    pipe_through :api

    post "/auth/login", AuthController, :login
  end

  if Application.compile_env(:pergamino, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: Pergamino.Telemetry
    end
  end
end
