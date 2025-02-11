defmodule SurrealEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :surrealdb_ex,
      description: "A Surreal DB driver for Elixir language",
      version: "0.0.1",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      preferred_cli_env: preferred_cli_env(),
      package: package()
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
      {:exconstructor, "~> 1.2.11"},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:mix_test_watch, "~> 1.0", only: [:dev, :test], runtime: false}
    ]
  end

  defp package() do
    [
      name: "surrealdb_ex",
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/joojscript/surrealdb_ex"}
    ]
  end

  defp preferred_cli_env do
    [
      "test.watch": :test
    ]
  end
end
