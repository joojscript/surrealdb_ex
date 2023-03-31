defmodule SurrealEx.Channels.Http do
  use Agent

  @type http_opts :: [
          hostname: String.t(),
          port: integer(),
          namespace: String.t(),
          database: String.t(),
          username: String.t(),
          password: String.t()
        ]

  @spec default_opts :: http_opts()
  def default_opts,
    do: [
      hostname: "localhost",
      port: 8000,
      namespace: "default",
      database: "default",
      username: "root",
      password: "root"
    ]

  @spec start_link(http_opts()) :: Agent.on_start()
  def start_link(opts) do
    before_connect()

    opts = Keyword.merge(default_opts(), opts)

    Agent.start_link(fn -> opts end, name: __MODULE__)
  end

  @spec stop(pid()) :: :ok | {:error, term()}
  def stop(pid) do
    Agent.stop(pid)
  end

  @doc """
    This is the main way to dispatch a query against Surreal DB HTTP endpoint.

    It sends a POST request to `/sql` endpoint with the query as the body.

    ## Examples

        iex> SurrealEx.Channels.Http.query("SELECT 1")
        {:ok, %{data: %{rows: [[1]]}, error: nil, status: 200}}
  """
  @spec query(String.t(), keyword(any())) :: {:ok, term(), term()} | {:error, term()}
  def query(query, params \\ []) do
    opts = Agent.get(__MODULE__, fn state -> state end) |> Keyword.merge(params)
    hostname = Keyword.get(opts, :hostname, "127.0.0.1")
    port = Keyword.get(opts, :port, 8000)
    timeout = Keyword.get(opts, :timeout, 5000)
    namespace = Keyword.get(opts, :namespace, "default")
    database = Keyword.get(opts, :database, "default")
    username = Keyword.get(opts, :username, "root")
    password = Keyword.get(opts, :password, "root")

    try do
      {:ok, {_, _, result}} =
        :httpc.request(
          :post,
          {
            ~c"http://#{username}:#{password}@#{hostname}:#{port}/sql",
            [
              {~c"Accept", ~c"application/json"},
              {~c"Accept-Encoding", ~c"gzip, deflate"},
              {~c"Cache-Control", ~c"max-age=0"},
              {~c"Connection", ~c"keep-alive"},
              {~c"Host", ~c"#{hostname}:#{port}"},
              {~c"Upgrade-Insecure-Requests", ~c"1"},
              {~c"NS", ~c"#{database}"},
              {~c"DB", ~c"#{namespace}"}
            ],
            ~c"application/json",
            ~c"#{query}"
          },
          [
            {~c"timeout", ~c"#{timeout}"}
          ],
          []
        )

      {:ok, result |> to_string |> Jason.decode!()}
    rescue
      e in RuntimeError -> {:error, e}
      e -> {:error, e}
    end
  end

  defp before_connect() do
    :inets.start()
    :ssl.start()
  end
end
