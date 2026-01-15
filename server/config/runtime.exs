import Config

if System.get_env("PHX_SERVER") do
  config :pergamino, Pergamino.Web.Endpoint, server: true
end

config :pergamino,
       :jwt_secret_key,
       System.get_env("JWT_SECRET_KEY") || "zR8pY6uX3vB9mK2nL5qA8sD1fG4hJ7jK0lZ2xX4c6vB8nM0m"

config :pergamino, Pergamino.Web.Endpoint,
  http: [port: String.to_integer(System.get_env("PORT", "4000"))]

if config_env() == :prod do
  host = System.get_env("PHX_HOST") || "example.com"

  config :pergamino, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :pergamino, Pergamino.Web.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [ip: {0, 0, 0, 0, 0, 0, 0, 0}]
end
