defmodule Pergamino.Web.Endpoint do
  use Phoenix.Endpoint, otp_app: :pergamino

  if code_reloading? do
    plug(Phoenix.CodeReloader)
  end

  plug(Plug.RequestId)

  socket("/socket", Pergamino.Web.Channels.UserSocket,
    websocket: true,
    longpoll: false
  )

  plug(Plug.Telemetry, event_prefix: [:phoenix, :endpoint])

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()
  )

  plug(Plug.Session,
    store: :cookie,
    key: "_pergamino_key",
    signing_salt: "SECRET_SIGNING_SALT",
    same_site: "Lax"
  )

  plug(Pergamino.Web.Router)
end
