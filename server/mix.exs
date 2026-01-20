defmodule Pergamino.MixProject do
  use Mix.Project

  def project do
    [
      app: :pergamino,
      version: "0.1.0",
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      listeners: [Phoenix.CodeReloader]
    ]
  end

  def application do
    [
      mod: {Pergamino.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  def cli do
    [
      preferred_envs: [precommit: :test]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:phoenix, "~> 1.8.3"},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:jason, "~> 1.4"},
      {:dns_cluster, "~> 0.2.0"},
      {:bandit, "~> 1.5"},
      {:joken, "~> 2.6"},
      {:swoosh, "~> 1.16"},
      {:finch, "~> 0.16"},
      {:mox, "~> 1.0", only: :test}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "setup.ssl"],
      precommit: ["compile --warnings-as-errors", "deps.unlock --unused", "format", "test"]
    ]
  end
end
