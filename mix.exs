defmodule SurrealEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :surreal_ex,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      preferred_cli_env: preferred_cli_env()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :inets, :ssl]
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.4"},
      {:websockex, "~> 0.4.3"},
      {:mock, "~> 0.3.0", only: :test},
      {:mix_test_watch, "~> 1.0", only: [:dev, :test], runtime: false}
    ]
  end

  defp preferred_cli_env do
    [
      "test.watch": :test
    ]
  end
end
