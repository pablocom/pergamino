import Config

config :pergamino,
  generators: [timestamp_type: :utc_datetime]

config :pergamino, Pergamino.Web.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: Pergamino.Web.Controllers.ErrorJSON],
    layout: false
  ],
  https: [
    port: 4001,
    cipher_suite: :strong,
    certfile: "priv/cert/localhost.pem",
    keyfile: "priv/cert/localhost_key.pem"
  ],
  pubsub_server: Pergamino.PubSub,
  live_view: [signing_salt: "SECRET_SALT"]

config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :pergamino, Pergamino.Infrastructure.Messaging.EmailSender, adapter: Swoosh.Adapters.Test

config :swoosh, :api_client, Swoosh.ApiClient.Finch

config :phoenix, :json_library, Jason

config :pergamino, :redis,
  pool_size: 10,
  url: "redis://localhost:6379/0"

import_config "#{config_env()}.exs"
