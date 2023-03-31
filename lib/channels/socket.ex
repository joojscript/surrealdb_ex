defmodule SurrealEx.Channels.Socket do
  require Logger

  use WebSockex

  @type socket_opts :: [
          hostname: String.t(),
          port: integer(),
          namespace: String.t(),
          database: String.t(),
          username: String.t(),
          password: String.t()
        ]

  @spec default_opts :: socket_opts()
  def default_opts,
    do: [
      hostname: "localhost",
      port: 8000,
      namespace: "default",
      database: "default",
      username: "root",
      password: "root"
    ]

  @spec start_link(socket_opts()) :: WebSockex.on_start()
  def start_link(opts \\ []) do
    opts = Keyword.merge(default_opts(), opts)

    hostname = Keyword.get(opts, :hostname)
    port = Keyword.get(opts, :port)

    WebSockex.start_link("ws://#{hostname}:#{port}/rpc", __MODULE__, opts)
  end

  @spec stop(pid()) :: :ok | {:error, term()}
  def stop(pid) do
    cond do
      Process.exit(pid, :kill) -> :ok
      true -> {:error, "Could not stop process"}
    end
  end

  def handle_frame({type, msg}, state) do
    Logger.info("Received Message - Type: #{inspect(type)} -- Message: #{inspect(msg)}")
    IO.inspect(Jason.decode!(msg))
    {:ok, state}
  end

  @spec build_cast_payload(String.t(), keyword(any())) :: String.t()
  defp build_cast_payload(method, args) do
    # Build a payload for a cast message to Surreal DB WebSocket endpoint.
    # REFERENCE: https://github.com/surrealdb/surrealdb.js/blob/ce949aeddd2b451b3b7b473705e62fbbc58e095b/src/index.ts#L621

    params =
      case method do
        "query" -> [args[:query], args[:payload]]
        "signin" -> [args[:payload]]
        "use" -> [args[:namespace], args[:database]]
      end

    IO.inspect(args)

    %{
      "id" => :rand.uniform(9999) |> to_string(),
      "method" => method,
      "params" => params
    }
    |> Jason.encode!()
  end

  # REFERENCE: https://github.com/surrealdb/surrealdb.js/blob/ce949aeddd2b451b3b7b473705e62fbbc58e095b/src/index.ts#L72
  @type sign_in_payload :: %{
          NS: String.t(),
          DB: String.t(),
          user: String.t(),
          pass: String.t()
        }
  @doc """
    Sends a `signin` frame to Surreal DB WebSocket endpoint.
  """
  @spec sign_in(pid(), sign_in_payload()) :: :ok | {:error, term()}
  def sign_in(pid, payload) do
    WebSockex.cast(pid, {"signin", [payload: payload]})
  end

  @doc """
    Sends a `query` frame to Surreal DB WebSocket endpoint.
  """
  @spec query(pid, String.t(), map()) :: :ok
  def query(pid, query, payload) do
    WebSockex.cast(pid, {"query", [query: query, payload: payload]})
  end

  @spec use(pid(), String.t(), String.t()) :: :ok
  def use(pid, namespace, database) do
    WebSockex.cast(pid, {"use", [namespace: namespace, database: database]})
  end

  def handle_cast(caller, state) do
    {method, args} = caller

    payload = build_cast_payload(method, args)

    frame = {:text, payload}
    Logger.info("Sending #{method} frame with payload: #{payload}")
    {:reply, frame, state}
  end
end
