defmodule SurrealEx.Socket do
  alias SurrealEx.Operations
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

  @type base_connection_opts :: socket_opts()
  @base_connection_opts Application.compile_env(:surrealdb_ex, :connection_config,
                          hostname: "localhost",
                          port: 8000,
                          namespace: "default",
                          database: "default",
                          username: "root",
                          password: "root"
                        )

  @spec start_link(socket_opts()) :: WebSockex.on_start()
  def start_link(opts \\ []) do
    opts =
      Keyword.merge(
        @base_connection_opts,
        opts
      )

    hostname = Keyword.get(opts, :hostname)
    port = Keyword.get(opts, :port)

    WebSockex.start_link("ws://#{hostname}:#{port}/rpc", __MODULE__, opts)
  end

  @spec stop(pid()) :: :ok
  def stop(pid) do
    Process.exit(pid, :kill)
    :ok
  end

  def handle_frame({_type, msg}, state) do
    task = Keyword.get(state, :__receiver__)

    Process.send(
      task.pid,
      {:ok, msg |> Jason.decode!()},
      []
    )

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

  @type task_opts :: [
          timeout: integer() | :infinity
        ]
  defp task_opts_default, do: [timeout: :infinity]

  @spec declare_and_run(pid(), {String.t(), keyword()}, task_opts()) ::
          Operations.common_response()
  defp declare_and_run(pid, {method, args}, opts \\ []) do
    task =
      Task.async(fn ->
        receive do
          {:ok, msg} -> {:ok, msg}
          {:error, reason} -> {:error, reason}
          _ -> {:error, "Unknown Error"}
        end
      end)

    Process.monitor(task.pid)

    WebSockex.cast(pid, {method, Keyword.merge([__receiver__: task], args)})

    task_timeout = Keyword.get(opts, :timeout, :infinity)
    Task.await(task, task_timeout)
  end

  ## Operations Implementation:

  def sign_in(pid, payload) when is_pid(pid) and is_map(payload),
    do: declare_and_run(pid, {"signin", [payload: payload]})

  def sign_in(pid, payload, %Task{} = task, opts)
      when is_pid(pid) and is_struct(task) and is_map(payload),
      do:
        declare_and_run(
          pid,
          {"signin", [payload: payload, __receiver__: task]},
          opts |> Keyword.merge(task_opts_default())
        )

  def query(pid, query, payload)
      when (is_pid(pid) and is_binary(query) and is_map(payload)) or is_struct(payload),
      do: declare_and_run(pid, {"query", [query: query, payload: payload]})

  def query(pid, query, payload, %Task{} = task, opts \\ task_opts_default())
      when is_pid(pid) and is_binary(query) and is_map(payload) and is_struct(task),
      do:
        declare_and_run(
          pid,
          {"query", [query: query, payload: payload, __receiver__: task]},
          opts
        )

  def use(pid, namespace, database)
      when is_pid(pid) and is_binary(namespace) and is_binary(database),
      do: declare_and_run(pid, {"use", [namespace: namespace, database: database]})

  def use(pid, namespace, database, %Task{} = task, opts \\ task_opts_default())
      when is_pid(pid) and is_binary(namespace) and is_binary(database) and is_struct(task),
      do:
        declare_and_run(
          pid,
          {"use", [namespace: namespace, database: database, __receiver__: task]},
          opts
        )

  def authenticate(pid, token) when is_pid(pid) and is_binary(token),
    do: declare_and_run(pid, {"authenticate", [token: token]})

  def authenticate(pid, token, %Task{} = task, opts \\ task_opts_default())
      when is_pid(pid) and is_binary(token) and is_struct(task),
      do: declare_and_run(pid, {"authenticate", [token: token, __receiver__: task]}, opts)

  def change(pid, table, payload)
      when (is_pid(pid) and is_binary(table) and is_map(payload)) or is_struct(payload),
      do: declare_and_run(pid, {"change", [table: table, payload: payload]})

  def change(pid, table, payload, %Task{} = task, opts \\ task_opts_default())
      when (is_pid(pid) and is_binary(table) and is_map(payload)) or
             (is_struct(payload) and is_struct(task)),
      do:
        declare_and_run(
          pid,
          {"change", [table: table, payload: payload, __receiver__: task]},
          opts
        )

  def create(pid, table, payload)
      when (is_pid(pid) and is_binary(table) and is_map(payload)) or is_struct(payload),
      do: declare_and_run(pid, {"create", [table: table, payload: payload]})

  def create(pid, table, payload, %Task{} = task, opts \\ task_opts_default())
      when (is_pid(pid) and is_binary(table) and is_map(payload)) or
             (is_struct(payload) and is_struct(task)),
      do:
        declare_and_run(
          pid,
          {"create", [table: table, payload: payload, __receiver__: task]},
          opts
        )

  def delete(pid, table) when is_pid(pid) and is_binary(table),
    do: declare_and_run(pid, {"delete", [table: table]})

  def delete(pid, table, %Task{} = task, opts \\ task_opts_default())
      when is_pid(pid) and is_binary(table) and is_struct(task),
      do: declare_and_run(pid, {"delete", [table: table, __receiver__: task]}, opts)

  def info(pid) when is_pid(pid), do: declare_and_run(pid, {"info", []})

  def info(pid, %Task{} = task, opts \\ task_opts_default())
      when is_pid(pid) and is_struct(task),
      do: declare_and_run(pid, {"info", [__receiver__: task]}, opts)

  def invalidate(pid) when is_pid(pid), do: declare_and_run(pid, {"invalidate", []})

  def invalidate(pid, %Task{} = task, opts \\ task_opts_default())
      when is_pid(pid) and is_struct(task),
      do: declare_and_run(pid, {"invalidate", [__receiver__: task]}, opts)

  def kill(pid, query) when is_pid(pid) and is_binary(query),
    do: declare_and_run(pid, {"kill", [query: query]})

  def kill(pid, query, %Task{} = task, opts \\ task_opts_default())
      when is_pid(pid) and is_binary(query) and is_struct(task),
      do: declare_and_run(pid, {"kill", [query: query, __receiver__: task]}, opts)

  def let(pid, key, value) when is_pid(pid) and is_binary(key) and is_binary(value),
    do: declare_and_run(pid, {"let", [key: key, value: value]})

  def let(pid, key, value, %Task{} = task, opts \\ task_opts_default())
      when is_pid(pid) and is_binary(key) and is_binary(value) and is_struct(task),
      do: declare_and_run(pid, {"let", [key: key, value: value, __receiver__: task]}, opts)

  def live(pid, table) when is_pid(pid) and is_binary(table),
    do: declare_and_run(pid, {"live", [table: table]})

  def live(pid, table, %Task{} = task, opts \\ task_opts_default())
      when is_pid(pid) and is_binary(table) and is_struct(task),
      do: declare_and_run(pid, {"live", [table: table, __receiver__: task]}, opts)

  def modify(pid, table, payload)
      when is_pid(pid) and is_binary(table) and is_list(payload),
      do: declare_and_run(pid, {"modify", [table: table, payload: payload]})

  def modify(pid, table, payload, %Task{} = task, opts \\ task_opts_default())
      when is_pid(pid) and is_binary(table) and is_list(payload) and is_struct(task),
      do:
        declare_and_run(
          pid,
          {"modify", [table: table, payload: payload, __receiver__: task]},
          opts
        )

  def ping(pid) when is_pid(pid), do: declare_and_run(pid, {"ping", []})

  def ping(pid, %Task{} = task, opts \\ task_opts_default())
      when is_pid(pid) and is_struct(task),
      do: declare_and_run(pid, {"ping", [__receiver__: task]}, opts)

  def select(pid, query) when is_pid(pid) and is_binary(query),
    do: declare_and_run(pid, {"select", [query: query]})

  def select(pid, query, %Task{} = task, opts \\ task_opts_default())
      when is_pid(pid) and is_binary(query) and is_struct(task),
      do: declare_and_run(pid, {"select", [query: query, __receiver__: task]}, opts)

  def sign_up(pid, payload) when (is_pid(pid) and is_map(payload)) or is_struct(payload),
    do: declare_and_run(pid, {"signup", [payload: payload]})

  def sign_up(pid, payload, %Task{} = task, opts \\ task_opts_default())
      when (is_pid(pid) and is_map(payload)) or (is_struct(payload) and is_struct(task)),
      do: declare_and_run(pid, {"signup", [payload: payload, __receiver__: task]}, opts)

  def update(pid, table, payload)
      when (is_pid(pid) and is_binary(table) and is_map(payload)) or is_struct(payload),
      do: declare_and_run(pid, {"update", [table: table, payload: payload]})

  def update(pid, table, payload, %Task{} = task, opts \\ task_opts_default())
      when (is_pid(pid) and is_binary(table) and is_map(payload)) or
             (is_struct(payload) and is_struct(task)),
      do:
        declare_and_run(
          pid,
          {"update", [table: table, payload: payload, __receiver__: task]},
          opts
        )

  def handle_cast(caller, _state) do
    {method, args} = caller

    payload = build_cast_payload(method, args)

    frame = {:text, payload}
    {:reply, frame, args}
  end
end
