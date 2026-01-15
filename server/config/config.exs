import Config

config :pergamino,
  generators: [timestamp_type: :utc_datetime]

config :pergamino, Pergamino.Web.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: Pergamino.ErrorJSON],
    layout: false
  ],
  pubsub_server: Pergamino.PubSub,
  live_view: [signing_salt: "SECRET_SALT"]

config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

import_config "#{config_env()}.exs"
