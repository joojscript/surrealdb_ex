defmodule SurrealEx.Types.DriverOpts do
  @type t :: [
          {:hostname, String.t()},
          {:port, non_neg_integer()},
          {:username, String.t()},
          {:password, String.t()},
          {:database, String.t()},
          {:ssl, boolean()},
          {:ssl_opts, list()},
          {:singleton?, boolean()},
          {:channel, :http | :socket}
        ]

  defstruct [:hostname, :port, :username, :password, :database, :ssl, :ssl_opts, :singleton?]

  @spec default :: __MODULE__.t()
  def default,
    do: [
      hostname: "localhost",
      port: 8000,
      username: "admin",
      password: "admin",
      database: "default",
      ssl: false,
      ssl_opts: [],
      singleton?: true,
      channel: :http
    ]
end
