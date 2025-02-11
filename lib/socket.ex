defmodule SurrealEx.Socket do
  use WebSockex
  use SurrealEx.Macros

  alias SurrealEx.Domain

  @base_connection_opts Application.compile_env(:surrealdb_ex, :connection_config,
                          hostname: "localhost",
                          port: 8000,
                          namespace: "default",
                          database: "default",
                          username: "root",
                          password: "root"
                        )

  @spec child_spec(Domain.SocketOpts.t()) :: map()
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker
    }
  end

  @typep socket_response :: {:ok, Domain.ExecutionSuccess} | {:error, Domain.ExecutionError}
  @typep process_identifier :: pid | atom
  @type payload_type :: map() | struct()

  @spec start_link(Domain.SocketOpts.t()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    opts =
      Keyword.merge(
        @base_connection_opts,
        opts
      )

    hostname = Keyword.get(opts, :hostname)
    port = Keyword.get(opts, :port)

    case WebSockex.start_link("ws://#{hostname}:#{port}/rpc", __MODULE__, opts) do
      {:error, reason} ->
        {:error, reason}

      {:ok, pid} ->
        opts = Keyword.merge(opts, socket_pid: pid)
        apply_hooks(pid, opts)
        {:ok, pid}
    end
  end

  @spec stop(pid()) :: :ok
  def stop(pid) do
    Process.exit(pid, :kill)
    :ok
  end

  @spec handle_frame({String, String}, map) :: {:ok, map}
  def handle_frame({_type, msg}, state) do
    task = Keyword.get(state, :__receiver__)
    decoded_payload = Jason.decode!(msg)

    Process.send(
      task.pid,
      {:ok, decoded_payload},
      []
    )

    {:ok, state}
  end

  @spec handle_cast(String, map) :: {:reply, {:text, map}, map}
  def handle_cast(caller, _state) do
    {method, args} = caller

    payload = build_cast_payload(method, args)

    frame = {:text, payload}
    state = args |> Keyword.merge(method: method)
    {:reply, frame, state}
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

  @spec declare_and_run(process_identifier, {String, keyword}, Domain.TaskOpts) ::
          socket_response()
  defp declare_and_run(pid, {method, args}, opts \\ []) do
    pid = if is_atom(pid), do: Process.whereis(pid), else: pid

    task =
      Task.async(fn ->
        receive do
          {:ok, msg} ->
            if is_map(msg) and Map.has_key?(msg, "error"),
              do: {:error, Domain.ExecutionError.SurrealError.new(msg["error"])},
              else: {:ok, Domain.ExecutionSuccess.new(msg)}

          {:error, reason} ->
            {:error, Domain.ExecutionError.SurrealError.new(reason)}

          _ ->
            error = %{code: -1, message: "Unknown Error"}
            {:error, Domain.ExecutionError.SurrealError.new(error)}
        end
      end)

    cast_args = args |> Keyword.merge(__receiver__: task)
    WebSockex.cast(pid, {method, cast_args})

    task_timeout = Keyword.get(opts, :timeout, :infinity)
    Task.await(task, task_timeout)
  end

  ## Operations Implementation:

  @doc """
    Signs in to a specific authentication scope.

      iex> {:ok, pid} = SurrealEx.start_link() # Include your connection options
      iex> {:ok, result} = SurrealEx.signin(pid, %{user: "root", pass: "root"})

      # SUCCESS CASE:
      {:ok, %{"id" => "6420", "result" => ""}}

      # ERROR CASE:
      {:error,
        %{
        "error" => %{
          "code" => -32000,
          "message" => "There was a problem with authentication"
        },
        "id" => "7335"
      }}
  """
  @spec signin(process_identifier, Domain.SignInPayload, Task, Domain.TaskOpts) ::
          socket_response()
  def signin(pid, payload)
      when is_process_identifier(pid) and is_payload_type(payload),
      do: declare_and_run(pid, {"signin", [payload: payload]})

  @spec signin(process_identifier, payload_type, Task, Domain.TaskOpts) :: socket_response()
  def signin(pid, payload, %Task{} = task, opts \\ Domain.TaskOpts.default())
      when is_process_identifier(pid) and is_payload_type(payload),
      do:
        declare_and_run(
          pid,
          {"signin", [payload: payload, __receiver__: task]},
          opts |> Keyword.merge(Domain.TaskOpts.default())
        )

  @doc """
    Runs a set of SurrealQL statements against the database.

      iex> {:ok, pid} = SurrealEx.start_link() # Include your connection options
      iex> {:ok, result} = SurrealEx.query(pid, "SELECT * FROM type::table($table) WHERE admin = true;", %{table: "users"})

      # SUCCESS CASE:
      {:ok,
        %{
          "id" => "6042",
          "result" => [
            %{
              "result" => [
                %{
                  "admin" => true,
                  "age" => 29,
                  "id" => "users:5ypb5ifhfo7tnj31pajl",
                  "name" => "John Doe"
                },
                %{
                  "admin" => true,
                  "age" => 32,
                  "id" => "users:zb71vk0kh9d33bucozr7",
                  "name" => "Mary Jane"
                }
              ],
              "status" => "OK",
              "time" => "80.164µs"
            }
          ]
        }
      }

      # ERROR CASE:
      {:error,
        %{
          "error" => %{
            "code" => -32000,
            "message" => "There was a problem with the database: Parse error on line 1 at character 0 when parsing [...]"
          },
          "id" => "1120"
        }
      }
  """
  @spec query(process_identifier, String, payload_type) :: socket_response
  def query(pid, query, payload)
      when is_process_identifier(pid) and is_payload_type(payload),
      do: declare_and_run(pid, {"query", [query: query, payload: payload]})

  @spec query(process_identifier, binary, payload_type, Task, Domain.TaskOpts) :: socket_response
  def query(pid, query, payload, %Task{} = task, opts \\ Domain.TaskOpts.default())
      when is_process_identifier(pid) and is_payload_type(payload) and
             is_struct(task),
      do:
        declare_and_run(
          pid,
          {"query", [query: query, payload: payload, __receiver__: task]},
          opts
        )

  @doc """
    Switch to a specific namespace and database.

      iex> {:ok, pid} = SurrealEx.start_link() # Include your connection options
      iex> {:ok, result} = SurrealEx.use(pid, "default", "default")

      # SUCCESS CASE:
      {:ok, %{"id" => "1915", "result" => nil}}

      # ERROR CASE:
      {:error,
        %{
          "error" => %{
            "code" => -32000,
            "message" => "There was a problem with the database: [...]"
          },
          "id" => "1120"
        }
      }
  """
  @spec use(process_identifier, String, String) :: socket_response
  def use(pid, namespace, database)
      when is_process_identifier(pid) and is_binary(namespace) and is_binary(database),
      do: declare_and_run(pid, {"use", [namespace: namespace, database: database]})

  @spec use(process_identifier, binary, binary, Task, Domain.TaskOpts) :: socket_response
  def use(pid, namespace, database, %Task{} = task, opts \\ Domain.TaskOpts.default())
      when is_process_identifier(pid) and is_binary(namespace) and is_binary(database) and
             is_struct(task),
      do:
        declare_and_run(
          pid,
          {"use", [namespace: namespace, database: database, __receiver__: task]},
          opts
        )

  @doc """
    Authenticates the current connection with a JWT token.

      iex> {:ok, pid} = SurrealEx.start_link() # Include your connection options
      iex> {:ok, result} = SurrealEx.authenticate(pid, "[YOUR JWT TOKEN HERE]")

      # SUCCESS CASE:
      {:ok, %{"id" => "1915", "result" => nil}}

      # ERROR CASE:
      {:error,
        %{
          "error" => %{
            "code" => -32000,
            "message" => "There was a problem with authentication"
          },
          "id" => "1492"
        }
      }
  """
  @spec authenticate(process_identifier, String) :: socket_response
  def authenticate(pid, token) when is_process_identifier(pid) and is_binary(token),
    do: declare_and_run(pid, {"authenticate", [token: token]})

  @spec authenticate(process_identifier, String, Task, Domain.TaskOpts) :: socket_response
  def authenticate(pid, token, %Task{} = task, opts \\ Domain.TaskOpts.default())
      when is_process_identifier(pid) and is_binary(token) and is_struct(task),
      do: declare_and_run(pid, {"authenticate", [token: token, __receiver__: task]}, opts)

  @doc """
    Modifies all records in a table, or a specific record, in the database.

      iex> {:ok, pid} = SurrealEx.start_link() # Include your connection options
      iex> {:ok, result} = SurrealEx.change(pid, "users:tobie", %{admin: true})

      # SUCCESS CASE:
      {:ok, %{"id" => "303", "result" => [%{"admin" => true, "id" => "users:tobie"}]}}

      # ERROR CASE:
      {:error,
        %{
          "error" => %{
            "code" => -32000,
            "message" => "[...]"
          },
          "id" => "6432"
        }
      }
  """
  @spec change(process_identifier, String, payload_type) :: socket_response
  def change(pid, table, payload)
      when is_process_identifier(pid) and is_binary(table) and
             (is_map(payload) or
                is_struct(payload)),
      do: declare_and_run(pid, {"change", [table: table, payload: payload]})

  @spec change(process_identifier, String, payload_type, Task, Domain.TaskOpts) :: socket_response
  def change(pid, table, payload, %Task{} = task, opts \\ Domain.TaskOpts.default())
      when is_process_identifier(pid) and is_binary(table) and
             is_payload_type(payload) and
             is_struct(task),
      do:
        declare_and_run(
          pid,
          {"change", [table: table, payload: payload, __receiver__: task]},
          opts
        )

  @doc """
    Creates a record in the database.

      iex> {:ok, pid} = SurrealEx.start_link() # Include your connection options
      iex> {:ok, result} = SurrealEx.create(pid, "users", %{name: "John Doe", age: 30})

      # SUCCESS CASE:
      {:ok,
        %{
          "id" => "9802",
          "result" => [
            %{"age" => 30, "id" => "users:agboh28f2vvy18d91q04", "name" => "John Doe"}
          ]
        }
      }

      # ERROR CASE:
      {:error,
        %{
          "error" => %{
            "code" => -32000,
            "message" => "[...]"
          },
          "id" => "2578"
        }
      }
  """
  @spec create(process_identifier, String, payload_type) :: socket_response
  def create(pid, table, payload)
      when is_binary(table) and is_payload_type(payload),
      do: declare_and_run(pid, {"create", [table: table, payload: payload]})

  @spec create(process_identifier, String, payload_type, Task, Domain.TaskOpts) :: socket_response
  def create(pid, table, payload, %Task{} = task, opts \\ Domain.TaskOpts.default())
      when is_binary(table) and
             (is_map(payload) or
                is_struct(payload)) and is_struct(task),
      do:
        declare_and_run(
          pid,
          {"create", [table: table, payload: payload, __receiver__: task]},
          opts
        )

  @doc """
    Deletes all records in a table, or a specific record, from the database.

      iex> {:ok, pid} = SurrealEx.start_link() # Include your connection options
      iex> {:ok, result} = SurrealEx.delete(pid, "users:jeremy")

      # SUCCESS CASE:
      {:ok, %{"id" => "4054", "result" => []}}

      # ERROR CASE:
      {:error,
        %{
          "error" => %{
            "code" => -32000,
            "message" => "[...]"
          },
          "id" => "2578"
        }
      }
  """
  @spec delete(process_identifier, String) :: socket_response
  def delete(pid, table) when is_process_identifier(pid) and is_binary(table),
    do: declare_and_run(pid, {"delete", [table: table]})

  @spec delete(process_identifier, String, Task, Domain.TaskOpts) :: socket_response
  def delete(pid, table, %Task{} = task, opts \\ Domain.TaskOpts.default())
      when is_process_identifier(pid) and is_binary(table) and is_struct(task),
      do: declare_and_run(pid, {"delete", [table: table, __receiver__: task]}, opts)

  @doc """
    Retreive info about the current Surreal instance.

      iex> {:ok, pid} = SurrealEx.start_link() # Include your connection options
      iex> {:ok, result} = SurrealEx.info(pid)

      # SUCCESS CASE:
      {:ok, %{"id" => "9250", "result" => nil}}

      # ERROR CASE:
      {:error,
        %{
          "error" => %{
            "code" => -32000,
            "message" => "[...]"
          },
          "id" => "2578"
        }
      }
  """
  @spec info(process_identifier) :: socket_response
  def info(pid) when is_process_identifier(pid), do: declare_and_run(pid, {"info", []})

  @spec info(process_identifier, Task, Domain.TaskOpts) :: socket_response
  def info(pid, %Task{} = task, opts \\ Domain.TaskOpts.default())
      when is_process_identifier(pid) and is_struct(task),
      do: declare_and_run(pid, {"info", [__receiver__: task]}, opts)

  @doc """
    Invalidates the authentication for the current connection.

      iex> {:ok, pid} = SurrealEx.start_link() # Include your connection options
      iex> {:ok, result} = SurrealEx.invalidate(pid)

      # SUCCESS CASE:
      {:ok, %{"id" => "9250", "result" => nil}}

      # ERROR CASE:
      {:error,
        %{
          "error" => %{
            "code" => -32000,
            "message" => "[...]"
          },
          "id" => "2578"
        }
      }
  """
  @spec invalidate(process_identifier) :: socket_response
  def invalidate(pid) when is_process_identifier(pid),
    do: declare_and_run(pid, {"invalidate", []})

  @spec invalidate(process_identifier, Task, Domain.TaskOpts) :: socket_response
  def invalidate(pid, %Task{} = task, opts \\ Domain.TaskOpts.default())
      when is_process_identifier(pid) and is_struct(task),
      do: declare_and_run(pid, {"invalidate", [__receiver__: task]}, opts)

  @doc """
    Kill a specific query.

      iex> {:ok, pid} = SurrealEx.start_link() # Include your connection options
      iex> {:ok, result} = SurrealEx.kill(pid)

      # SUCCESS CASE:
      {:ok, %{"id" => "9250", "result" => nil}}

      # ERROR CASE:
      {:error,
        %{
          "error" => %{
            "code" => -32000,
            "message" => "[...]"
          },
          "id" => "2578"
        }
      }
  """
  @spec kill(process_identifier, String) :: socket_response
  def kill(pid, query) when is_process_identifier(pid) and is_binary(query),
    do: declare_and_run(pid, {"kill", [query: query]})

  @spec kill(process_identifier, binary, Task, Domain.TaskOpts) :: socket_response
  def kill(pid, query, %Task{} = task, opts \\ Domain.TaskOpts.default())
      when is_process_identifier(pid) and is_binary(query) and is_struct(task),
      do: declare_and_run(pid, {"kill", [query: query, __receiver__: task]}, opts)

  @doc """
    Switch to a specific namespace and database.

      iex> {:ok, pid} = SurrealEx.start_link() # Include your connection options
      iex> {:ok, result} = SurrealEx.use(pid, "test", "test")

      # SUCCESS CASE:
      {:ok, %{"id" => "9250", "result" => nil}}

      # ERROR CASE:
      {:error,
        %{
          "error" => %{
            "code" => -32000,
            "message" => "[...]"
          },
          "id" => "2578"
        }
      }
  """
  @spec let(process_identifier, String, String) :: socket_response
  def let(pid, key, value)
      when is_process_identifier(pid) and is_binary(key) and is_binary(value),
      do: declare_and_run(pid, {"let", [key: key, value: value]})

  @spec let(process_identifier, binary, binary, Task, Domain.TaskOpts) :: socket_response
  def let(pid, key, value, %Task{} = task, opts \\ Domain.TaskOpts.default())
      when is_process_identifier(pid) and is_binary(key) and is_binary(value) and is_struct(task),
      do: declare_and_run(pid, {"let", [key: key, value: value, __receiver__: task]}, opts)

  @doc """
    Get a live status from a specific table or row.

      iex> {:ok, pid} = SurrealEx.start_link() # Include your connection options
      iex> {:ok, result} = SurrealEx.live(pid, "users")

      # SUCCESS CASE:
      {:ok, %{"id" => "8913", "result" => "8354534f-5e42-4bb7-8bae-6cf41d38236a"}}

      # ERROR CASE:
      {:error,
        %{
          "error" => %{
            "code" => -32000,
            "message" => "[...]"
          },
          "id" => "2578"
        }
      }
  """
  @spec live(process_identifier, String) :: socket_response
  def live(pid, table) when is_process_identifier(pid) and is_binary(table),
    do: declare_and_run(pid, {"live", [table: table]})

  @spec live(process_identifier, binary, Task, Domain.TaskOpts) :: socket_response
  def live(pid, table, %Task{} = task, opts \\ Domain.TaskOpts.default())
      when is_process_identifier(pid) and is_binary(table) and is_struct(task),
      do: declare_and_run(pid, {"live", [table: table, __receiver__: task]}, opts)

  @doc """
    Applies JSON Patch changes to all records, or a specific record, in the database.

      iex> {:ok, pid} = SurrealEx.start_link() # Include your connection options
      iex> {:ok, result} = SurrealEx.modify(pid, "users", %{"name" => "John Doe"})

      # SUCCESS CASE:
      {:ok, %{"id" => "8044", "result" => []}}

      # ERROR CASE:
      {:error,
        %{
          "error" => %{
            "code" => -32000,
            "message" => "[...]"
          },
          "id" => "2578"
        }
      }
  """
  @spec modify(process_identifier, String, list(payload_type)) :: socket_response
  def modify(pid, table, payload)
      when is_process_identifier(pid) and is_binary(table) and is_list(payload),
      do: declare_and_run(pid, {"modify", [table: table, payload: payload]})

  @spec modify(process_identifier, String, list(payload_type), Task, Domain.TaskOpts) ::
          socket_response
  def modify(pid, table, payload, %Task{} = task, opts \\ Domain.TaskOpts.default())
      when is_process_identifier(pid) and is_binary(table) and is_list(payload) and
             is_struct(task),
      do:
        declare_and_run(
          pid,
          {"modify", [table: table, payload: payload, __receiver__: task]},
          opts
        )

  @doc """
    Ping SurrealDB instance

      iex> {:ok, pid} = SurrealEx.start_link() # Include your connection options
      iex> {:ok, result} = SurrealEx.ping(pid)

      # SUCCESS CASE:
      {:ok, %{"id" => "4562", "result" => true}}

      # ERROR CASE:
      {:error,
        %{
          "error" => %{
            "code" => -32000,
            "message" => "[...]"
          },
          "id" => "2578"
        }
      }
  """
  @spec ping(process_identifier) :: socket_response
  def ping(pid) when is_process_identifier(pid), do: declare_and_run(pid, {"ping", []})

  @spec ping(process_identifier, Task, Domain.TaskOpts) :: socket_response
  def ping(pid, %Task{} = task, opts \\ Domain.TaskOpts.default())
      when is_process_identifier(pid) and is_struct(task),
      do: declare_and_run(pid, {"ping", [__receiver__: task]}, opts)

  @doc """
    Selects all records in a table, or a specific record, from the database.

      iex> {:ok, pid} = SurrealEx.start_link() # Include your connection options
      iex> {:ok, result} = SurrealEx.select(pid, "SELECT * FROM users;")

      # SUCCESS CASE:
      {:ok, %{"id" => "948", "result" => []}}

      # ERROR CASE:
      {:error,
        %{
          "error" => %{
            "code" => -32000,
            "message" => "[...]"
          },
          "id" => "2578"
        }
      }
  """
  @spec select(process_identifier, String) :: socket_response
  def select(pid, query) when is_binary(query),
    do: declare_and_run(pid, {"select", [query: query]})

  @spec select(process_identifier, String, Task, Domain.TaskOpts) :: socket_response
  def select(pid, query, %Task{} = task, opts \\ Domain.TaskOpts.default())
      when is_process_identifier(pid) and is_binary(query) and is_struct(task),
      do: declare_and_run(pid, {"select", [query: query, __receiver__: task]}, opts)

  @doc """
    Signs up to a specific authentication scope.

      iex> {:ok, pid} = SurrealEx.start_link() # Include your connection options
      iex> {:ok, result} = SurrealEx.signup(pid, %{user: "root", pass: "root", SC: "allusers", DB: "test", NS: "test"})

      # SUCCESS CASE:
      {:ok,
        %{
          "id" => "9267",
          "result" => "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9.eyJpYXQiOjE2ODA2NjE5NDksIm5iZiI6MTY4MDY2MTk0OSwiZXhwIjoxNjgxODcxNTQ5LCJpc3MiOiJTdXJyZWFsREIiLCJOUyI6InRlc3QiLCJEQiI6InRlc3QiLCJTQyI6ImFsbHVzZXJzIiwiSUQiOiJ1c2VyOjdqN2hubnloMGFseTV0cHlnb3JrIn0.7IZ7QL6BMgNv9xW_QHu-JrZdfDdX9ngGV5xlxNPHHIkPzgi9OW2iHdUt2wt8x4_5vRo9rijQge04Nvbl3aTV9A"
        }
      }

      # ERROR CASE:
      {:error,
        %{
          "error" => %{
            "code" => -32000,
            "message" => "There was a problem with authentication"
          },
          "id" => "3694"
        }
      }
  """
  @spec signup(process_identifier, payload_type) :: socket_response
  def signup(pid, payload)
      when is_process_identifier(pid) and is_payload_type(payload),
      do: declare_and_run(pid, {"signup", [payload: payload]})

  @spec signup(process_identifier, payload_type, Task, Domain.TaskOpts) :: socket_response
  def signup(pid, payload, %Task{} = task, opts \\ Domain.TaskOpts.default())
      when is_process_identifier(pid) and is_payload_type(payload) and
             is_struct(task),
      do: declare_and_run(pid, {"signup", [payload: payload, __receiver__: task]}, opts)

  @doc """
    Updates all records in a table, or a specific record, in the database.

      iex> {:ok, pid} = SurrealEx.start_link() # Include your connection options
      iex> {:ok, result} = SurrealEx.update(pid, "users:jeremy", %{admin: true})

      # SUCCESS CASE:
      {:ok, %{"id" => "6427", "result" => []}}

      # ERROR CASE:
      {:error,
        %{
          "error" => %{
            "code" => -32000,
            "message" => "There was a problem with authentication"
          },
          "id" => "3694"
        }
      }
  """
  @spec update(process_identifier, String, payload_type) :: socket_response
  def update(pid, table, payload)
      when is_process_identifier(pid) and is_binary(table) and is_payload_type(payload),
      do: declare_and_run(pid, {"update", [table: table, payload: payload]})

  @spec update(process_identifier, String, payload_type, Task, Domain.TaskOpts) :: socket_response
  def update(pid, table, payload, %Task{} = task, opts \\ Domain.TaskOpts.default())
      when is_process_identifier(pid) and is_binary(table) and is_struct(task) and
             is_payload_type(payload),
      do:
        declare_and_run(
          pid,
          {"update", [table: table, payload: payload, __receiver__: task]},
          opts
        )

  defp apply_hooks(pid, opts) do
    name = Keyword.get(opts, :name)

    if not is_nil(name) do
      Process.register(pid, name)
    end

    [username, password] = [Keyword.get(opts, :username), Keyword.get(opts, :password)]
    [namespace, database] = [Keyword.get(opts, :namespace), Keyword.get(opts, :database)]

    if not is_nil(username) and not is_nil(password) do
      {:ok, %{result: token}} =
        signin(pid, %{user: username, pass: password})

      authenticate(pid, token)
      __MODULE__.use(pid, namespace, database)
    end
  end
end
