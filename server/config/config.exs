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

config :ex_aws,
  access_key_id: "local",
  secret_access_key: "local",
  region: "us-east-1"

config :ex_aws, :dynamodb,
  scheme: "http://",
  host: "localhost",
  port: 8000,
  region: "us-east-1"

config :pergamino, :dynamodb, refresh_tokens_table: "refresh_tokens"

config :pergamino, :kafka,
  brokers: [{"localhost", 9092}],
  client_id: :pergamino_kafka_client,
  conversations_topic: "conversations",
  messages_topic: "chat-messages"

import_config "#{config_env()}.exs"
