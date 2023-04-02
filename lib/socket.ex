defmodule SurrealEx.Socket do
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

  @spec sign_in(pid(), keyword()) :: Operations.common_response()
  def sign_in(pid, payload) when is_pid(pid),
    do: declare_and_run(pid, {"signin", [payload: payload]})

  @spec sign_in(pid(), keyword(), Task.t(), task_opts()) :: term()
  def sign_in(pid, payload, %Task{} = task, opts \\ task_opts_default())
      when is_pid(pid) and is_struct(task),
      do: declare_and_run(pid, {"signin", [payload: payload, __receiver__: task]}, opts)

  @spec query(pid, String.t(), map()) :: Operations.common_response()
  def query(pid, query, payload),
    do: declare_and_run(pid, {"query", [query: query, payload: payload]})

  @spec query(pid, String.t(), map(), Task.t(), task_opts()) :: term()
  def query(pid, query, payload, %Task{} = task, opts \\ task_opts_default())
      when is_pid(pid) and is_struct(task),
      do:
        declare_and_run(
          pid,
          {"query", [query: query, payload: payload, __receiver__: task]},
          opts
        )

  @spec use(pid(), String.t(), String.t()) :: Operations.common_response()
  def use(pid, namespace, database),
    do: declare_and_run(pid, {"use", [namespace: namespace, database: database]})

  @spec use(pid(), String.t(), String.t(), Task.t(), task_opts()) :: term()
  def use(pid, namespace, database, %Task{} = task, opts \\ task_opts_default())
      when is_pid(pid) and is_struct(task),
      do:
        declare_and_run(
          pid,
          {"use", [namespace: namespace, database: database, __receiver__: task]},
          opts
        )

  @spec authenticate(pid(), String.t()) :: Operations.common_response()
  def authenticate(pid, token), do: declare_and_run(pid, {"authenticate", [token: token]})

  @spec authenticate(pid(), String.t(), Task.t(), task_opts()) :: term()
  def authenticate(pid, token, %Task{} = task, opts \\ task_opts_default())
      when is_pid(pid) and is_struct(task),
      do: declare_and_run(pid, {"authenticate", [token: token, __receiver__: task]}, opts)

  @spec change(pid(), String.t(), map()) :: Operations.common_response()
  def change(pid, table, payload),
    do: declare_and_run(pid, {"change", [table: table, payload: payload]})

  @spec change(pid(), String.t(), map(), Task.t(), task_opts()) :: term()
  def change(pid, table, payload, %Task{} = task, opts \\ task_opts_default())
      when is_pid(pid) and is_struct(task),
      do:
        declare_and_run(
          pid,
          {"change", [table: table, payload: payload, __receiver__: task]},
          opts
        )

  @spec create(pid(), String.t(), map()) :: Operations.common_response()
  def create(pid, table, payload),
    do: declare_and_run(pid, {"create", [table: table, payload: payload]})

  @spec create(pid(), String.t(), map(), Task.t(), task_opts()) :: term()
  def create(pid, table, payload, %Task{} = task, opts \\ task_opts_default())
      when is_pid(pid) and is_struct(task),
      do:
        declare_and_run(
          pid,
          {"create", [table: table, payload: payload, __receiver__: task]},
          opts
        )

  @spec delete(pid(), String.t()) :: Operations.common_response()
  def delete(pid, table), do: declare_and_run(pid, {"delete", [table: table]})

  @spec delete(pid(), String.t(), Task.t(), task_opts()) :: term()
  def delete(pid, table, %Task{} = task, opts \\ task_opts_default())
      when is_pid(pid) and is_struct(task),
      do: declare_and_run(pid, {"delete", [table: table, __receiver__: task]}, opts)

  @spec info(pid()) :: Operations.common_response()
  def info(pid), do: declare_and_run(pid, {"info", []})

  @spec info(pid(), Task.t(), task_opts()) :: term()
  def info(pid, %Task{} = task, opts \\ task_opts_default())
      when is_pid(pid) and is_struct(task),
      do: declare_and_run(pid, {"info", [__receiver__: task]}, opts)

  @spec invalidate(pid()) :: Operations.common_response()
  def invalidate(pid), do: declare_and_run(pid, {"invalidate", []})

  @spec invalidate(pid(), Task.t(), task_opts()) :: term()
  def invalidate(pid, %Task{} = task, opts \\ task_opts_default())
      when is_pid(pid) and is_struct(task),
      do: declare_and_run(pid, {"invalidate", [__receiver__: task]}, opts)

  @spec kill(pid(), String.t()) :: Operations.common_response()
  def kill(pid, query), do: declare_and_run(pid, {"kill", [query: query]})

  @spec kill(pid(), String.t(), Task.t(), task_opts()) :: term()
  def kill(pid, query, %Task{} = task, opts \\ task_opts_default())
      when is_pid(pid) and is_struct(task),
      do: declare_and_run(pid, {"kill", [query: query, __receiver__: task]}, opts)

  @spec let(pid(), String.t(), String.t()) :: Operations.common_response()
  def let(pid, key, value), do: declare_and_run(pid, {"let", [key: key, value: value]})

  @spec let(pid(), String.t(), String.t(), Task.t(), task_opts()) :: term()
  def let(pid, key, value, %Task{} = task, opts \\ task_opts_default())
      when is_pid(pid) and is_struct(task),
      do: declare_and_run(pid, {"let", [key: key, value: value, __receiver__: task]}, opts)

  @spec live(pid(), String.t()) :: Operations.common_response()
  def live(pid, table), do: declare_and_run(pid, {"live", [table: table]})

  @spec live(pid(), String.t(), Task.t(), task_opts()) :: term()
  def live(pid, table, %Task{} = task, opts \\ task_opts_default())
      when is_pid(pid) and is_struct(task),
      do: declare_and_run(pid, {"live", [table: table, __receiver__: task]}, opts)

  @spec modify(pid(), String.t(), map() | list(map())) :: Operations.common_response()
  def modify(pid, table, payload),
    do: declare_and_run(pid, {"modify", [table: table, payload: payload]})

  @spec modify(pid(), String.t(), map() | list(map()), Task.t(), task_opts()) :: term()
  def modify(pid, table, payload, %Task{} = task, opts \\ task_opts_default())
      when is_pid(pid) and is_struct(task),
      do:
        declare_and_run(
          pid,
          {"modify", [table: table, payload: payload, __receiver__: task]},
          opts
        )

  @spec ping(pid()) :: Operations.common_response()
  def ping(pid), do: declare_and_run(pid, {"ping", []})

  @spec ping(pid(), Task.t(), task_opts()) :: term()
  def ping(pid, %Task{} = task, opts \\ task_opts_default())
      when is_pid(pid) and is_struct(task),
      do: declare_and_run(pid, {"ping", [__receiver__: task]}, opts)

  @spec select(pid(), String.t()) :: Operations.common_response()
  def select(pid, query), do: declare_and_run(pid, {"select", [query: query]})

  @spec select(pid(), String.t(), Task.t(), task_opts()) :: term()
  def select(pid, query, %Task{} = task, opts \\ task_opts_default())
      when is_pid(pid) and is_struct(task),
      do: declare_and_run(pid, {"select", [query: query, __receiver__: task]}, opts)

  @spec sign_up(pid(), Operations.sign_up_payload()) :: Operations.common_response()
  def sign_up(pid, payload), do: declare_and_run(pid, {"signup", [payload: payload]})

  @spec sign_up(pid(), Operations.sign_up_payload(), Task.t(), task_opts()) :: term()
  def sign_up(pid, payload, %Task{} = task, opts \\ task_opts_default())
      when is_pid(pid) and is_struct(task),
      do: declare_and_run(pid, {"signup", [payload: payload, __receiver__: task]}, opts)

  @spec update(pid(), String.t(), map()) :: Operations.common_response()
  def update(pid, table, payload),
    do: declare_and_run(pid, {"update", [table: table, payload: payload]})

  @spec update(pid(), String.t(), map(), Task.t(), task_opts()) :: term()
  def update(pid, table, payload, %Task{} = task, opts \\ task_opts_default())
      when is_pid(pid) and is_struct(task),
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
