import Config

config :surrealdb_ex, :test_database_config,
  hostname: "localhost",
  port: 8000,
  username: "root",
  password: "root",
  database: "test",
  namespace: "test",
  surreal_cli_path: "/usr/local/bin/surreal"
