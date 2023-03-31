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
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:mix_test_watch, "~> 1.0", only: [:dev, :test], runtime: false}
    ]
  end

  defp preferred_cli_env do
    [
      "test.watch": :test
    ]
  end
end
