defmodule SurrealEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :surrealdb_ex,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      preferred_cli_env: preferred_cli_env(),

      # Docs
      name: "Surreal DB driver for Elixir",
      source_url: "https://github.com/joojscript/surrealdb_ex",
      homepage_url: "https://hex.pm/packages/surrealdb_ex",
      docs: [
        # The main page in the docs
        main: "Surreal DB driver for Elixir",
        logo: ".github/assets/logo.png",
        extras: ["README.md"]
      ]
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
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:mix_test_watch, "~> 1.0", only: [:dev, :test], runtime: false}
    ]
  end

  defp preferred_cli_env do
    [
      "test.watch": :test
    ]
  end
end
