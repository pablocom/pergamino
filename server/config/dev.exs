import Config

config :pergamino, Pergamino.Web.Endpoint,
  http: [ip: {127, 0, 0, 1}],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "cHLOJ5KP6lk1rNJicr6UMkG3rT9nN7rwkSapFnUqOXsolJQYXRiTrrJwFSAx3l/f",
  watchers: []

config :pergamino, dev_routes: true

config :pergamino, Pergamino.Mailer, adapter: Swoosh.Adapters.Local

config :logger, :default_formatter, format: "[$level] $message\n"

config :phoenix, :stacktrace_depth, 20

config :phoenix, :plug_init_mode, :runtime
