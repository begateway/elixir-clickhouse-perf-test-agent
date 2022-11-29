defmodule PTA.MixProject do
  use Mix.Project

  def project do
    [
      app: :perf_test_agent,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {PerfTestAgent, :no_args}
    ]
  end

  defp deps do
    [
      {:ecto, "~> 3.9"},
      {:prometheus_ex, "~> 3.0"},
      {:pillar, git: "https://github.com/begateway/pillar.git"},
      {:hackney, "~> 1.18"},
      {:postgrex, "~> 0.16.5"},
      {:myxql, "~> 0.6.3"},
      {:db_connection, "~> 2.4"},
      {:epgsql, "~> 4.6"}
    ]
  end
end
