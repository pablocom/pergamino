import Config

config :pergamino, Pergamino.Web.Endpoint,
  force_ssl: [rewrite_on: [:x_forwarded_proto]],
  exclude: [
    hosts: ["localhost", "127.0.0.1"]
  ]

config :logger, level: :info
