defmodule SurrealEx.Channels.Socket do
  require Logger

  use WebSockex
  use SurrealEx.Operations

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

  @spec stop(pid()) :: :ok
  def stop(pid) do
    Process.exit(pid, :kill)
    :ok
  end

  def handle_frame({type, msg}, state) do
    # Logger.info("Received Message - Type: #{inspect(type)} -- Message: #{inspect(msg)}")
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
        "signup" -> [args[:payload]]
        "use" -> [args[:namespace], args[:database]]
        "authenticate" -> [args[:token]]
        "change" -> [args[:table], args[:payload]]
        "create" -> [args[:table], args[:payload]]
        "delete" -> [args[:table]]
        "kill" -> [args[:query]]
        "let" -> [args[:key], args[:value]]
        "live" -> [args[:table]]
        "modify" -> [args[:table], args[:payload]]
        "select" -> [args[:query]]
        "update" -> [args[:table], args[:payload]]
        _ -> []
      end

    %{
      "id" => :rand.uniform(9999) |> to_string(),
      "method" => method,
      "params" => params
    }
    |> Jason.encode!()
  end

  ## Operations Implementation:

  @spec sign_in(pid(), keyword()) :: :ok | {:error, term()}
  def sign_in(pid, payload) do
    WebSockex.cast(pid, {"signin", [payload: payload]})
  end

  @spec query(pid, String.t(), map()) :: :ok | {:error, term()}
  def query(pid, query, payload) do
    WebSockex.cast(pid, {"query", [query: query, payload: payload]})
  end

  @spec use(pid(), String.t(), String.t()) :: :ok | {:error, term()}
  def use(pid, namespace, database) do
    WebSockex.cast(pid, {"use", [namespace: namespace, database: database]})
  end

  @spec authenticate(pid(), String.t()) :: :ok | {:error, term()}
  def authenticate(pid, token) do
    WebSockex.cast(pid, {"authenticate", [token]})
  end

  @spec change(pid(), String.t(), map()) :: :ok | {:error, term()}
  def change(pid, table, payload) do
    WebSockex.cast(pid, {"change", [table: table, payload: payload]})
  end

  @spec create(pid(), String.t(), map()) :: :ok | {:error, term()}
  def create(pid, table, payload) do
    WebSockex.cast(pid, {"create", [table: table, payload: payload]})
  end

  @spec delete(pid(), String.t()) :: :ok | {:error, term()}
  def delete(pid, table) do
    WebSockex.cast(pid, {"delete", [table: table]})
  end

  @spec info(pid()) :: :ok | {:error, term()}
  def info(pid) do
    WebSockex.cast(pid, {"info", []})
  end

  @spec invalidate(pid()) :: :ok | {:error, term()}
  def invalidate(pid) do
    WebSockex.cast(pid, {"invalidate", []})
  end

  @spec kill(pid(), String.t()) :: :ok | {:error, term()}
  def kill(pid, query) do
    WebSockex.cast(pid, {"kill", [query: query]})
  end

  @spec let(pid(), String.t(), String.t()) :: :ok | {:error, term()}
  def let(pid, key, value) do
    WebSockex.cast(pid, {"let", [key: key, value: value]})
  end

  @spec live(pid(), String.t()) :: :ok | {:error, term()}
  def live(pid, table) do
    WebSockex.cast(pid, {"live", [table: table]})
  end

  @spec modify(pid(), String.t(), map() | list(map())) :: :ok | {:error, term()}
  def modify(pid, table, payload) do
    WebSockex.cast(pid, {"modify", [table: table, payload: payload]})
  end

  @spec ping(pid()) :: :ok | {:error, term()}
  def ping(pid) do
    WebSockex.cast(pid, {"ping", []})
  end

  @spec select(pid(), String.t()) :: :ok | {:error, term()}
  def select(pid, query) do
    WebSockex.cast(pid, {"select", [query: query]})
  end

  @spec sign_up(pid(), Operations.sign_up_payload()) :: :ok | {:error, term()}
  def sign_up(pid, payload) do
    WebSockex.cast(pid, {"signup", [payload: payload]})
  end

  @spec update(pid(), String.t(), map()) :: :ok | {:error, term()}
  def update(pid, table, payload) do
    WebSockex.cast(pid, {"update", [table: table, payload: payload]})
  end

  def handle_cast(caller, state) do
    {method, args} = caller

    payload = build_cast_payload(method, args)

    frame = {:text, payload}
    # Logger.info("Sending #{method} frame with payload: #{payload}")
    {:reply, frame, state}
  end
end
