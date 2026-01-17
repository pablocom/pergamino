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
