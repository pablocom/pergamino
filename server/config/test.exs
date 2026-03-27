import Config

config :pergamino, Pergamino.Web.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "/CMSftyxv4Plh/vy9Es6S3wLOoi4Lvs8whr7xP9F9UmrbbQeogvz73aqpLQDTwLi",
  server: false

config :logger, level: :warning

config :pergamino, Pergamino.Infrastructure.Messaging.EmailSender, adapter: Swoosh.Adapters.Test

config :phoenix, :plug_init_mode, :runtime

config :phoenix, sort_verified_routes_query_params: true

config :pergamino, jwt_secret_key: "test_secret_key_123"

config :pergamino, :redis,
  pool_size: 2,
  url: System.get_env("REDIS_URL", "redis://localhost:6379/1")

config :ex_aws,
  access_key_id: "test",
  secret_access_key: "test",
  region: "us-east-1"

config :ex_aws, :dynamodb,
  scheme: "http://",
  host: "localhost",
  port: 8000,
  region: "us-east-1"

config :pergamino, :dynamodb, refresh_tokens_table: "test_refresh_tokens"

config :testcontainers, docker_url: System.get_env("DOCKER_HOST")

config :pergamino, :kafka,
  brokers: [{"localhost", 9092}],
  client_id: :pergamino_kafka_client,
  conversations_topic: "test-conversations",
  messages_topic: "test-chat-messages"

config :pergamino, :kafka_client_start_arg, :skip
