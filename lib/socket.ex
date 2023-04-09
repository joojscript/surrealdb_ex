defmodule SurrealEx.Socket do
  use WebSockex

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

  @spec declare_and_run(pid(), {String.t(), keyword()}, task_opts()) :: any()
  defp declare_and_run(pid, {method, args}, opts \\ []) do
    task =
      Task.async(fn ->
        receive do
          {:ok, msg} ->
            if is_map(msg) and Map.has_key?(msg, "error"), do: {:error, msg}, else: {:ok, msg}

          {:error, reason} ->
            {:error, reason}

          _ ->
            {:error, "Unknown Error"}
        end
      end)

    WebSockex.cast(pid, {method, Keyword.merge([__receiver__: task], args)})

    task_timeout = Keyword.get(opts, :timeout, :infinity)
    Task.await(task, task_timeout)
  end

  ## Operations Implementation:

  @type signup_payload :: %{
          user: String.t(),
          pass: String.t()
        }
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
  @spec signin(pid, signup_payload) :: any
  def signin(pid, payload) when (is_pid(pid) and is_map(payload)) or is_struct(payload),
    do: declare_and_run(pid, {"signin", [payload: payload]})

  @spec signin(pid, map | struct, Task.t(), task_opts) :: any
  def signin(pid, payload, %Task{} = task, opts \\ task_opts_default())
      when (is_pid(pid) and is_struct(task) and is_map(payload)) or is_struct(payload),
      do:
        declare_and_run(
          pid,
          {"signin", [payload: payload, __receiver__: task]},
          opts |> Keyword.merge(task_opts_default())
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
  @spec query(pid, String.t(), map | struct) :: any
  def query(pid, query, payload)
      when (is_pid(pid) and is_binary(query) and is_map(payload)) or is_struct(payload),
      do: declare_and_run(pid, {"query", [query: query, payload: payload]})

  @spec query(pid, binary, map | struct, Task.t(), task_opts) :: any
  def query(pid, query, payload, %Task{} = task, opts \\ task_opts_default())
      when is_pid(pid) and is_binary(query) and is_map(payload) and is_struct(task),
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
  @spec use(pid, String.t(), String.t()) :: any
  def use(pid, namespace, database)
      when is_pid(pid) and is_binary(namespace) and is_binary(database),
      do: declare_and_run(pid, {"use", [namespace: namespace, database: database]})

  @spec use(pid, binary, binary, Task.t(), task_opts()) :: any
  def use(pid, namespace, database, %Task{} = task, opts \\ task_opts_default())
      when is_pid(pid) and is_binary(namespace) and is_binary(database) and is_struct(task),
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
  @spec authenticate(pid, String.t()) :: any
  def authenticate(pid, token) when is_pid(pid) and is_binary(token),
    do: declare_and_run(pid, {"authenticate", [token: token]})

  @spec authenticate(pid, String.t(), Task.t(), task_opts) :: any
  def authenticate(pid, token, %Task{} = task, opts \\ task_opts_default())
      when is_pid(pid) and is_binary(token) and is_struct(task),
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
  @spec change(pid, String.t(), map | struct) :: any
  def change(pid, table, payload)
      when (is_pid(pid) and is_binary(table) and is_map(payload)) or is_struct(payload),
      do: declare_and_run(pid, {"change", [table: table, payload: payload]})

  @spec change(pid, String.t(), map | struct, Task.t(), task_opts()) :: any
  def change(pid, table, payload, %Task{} = task, opts \\ task_opts_default())
      when is_pid(pid) and is_binary(table) and (is_map(payload) or is_struct(payload)) and
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
  @spec create(pid, String.t(), map | struct) :: any
  def create(pid, table, payload)
      when (is_pid(pid) and is_binary(table) and is_map(payload)) or is_struct(payload),
      do: declare_and_run(pid, {"create", [table: table, payload: payload]})

  @spec create(pid, String.t(), map | struct, Task.t(), task_opts()) :: any
  def create(pid, table, payload, %Task{} = task, opts \\ task_opts_default())
      when is_pid(pid) and is_binary(table) and
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
  @spec delete(pid, String.t()) :: any
  def delete(pid, table) when is_pid(pid) and is_binary(table),
    do: declare_and_run(pid, {"delete", [table: table]})

  @spec delete(pid, String.t(), Task.t(), task_opts()) :: any
  def delete(pid, table, %Task{} = task, opts \\ task_opts_default())
      when is_pid(pid) and is_binary(table) and is_struct(task),
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
  @spec info(pid) :: any
  def info(pid) when is_pid(pid), do: declare_and_run(pid, {"info", []})

  @spec info(pid, Task.t(), task_opts()) :: any
  def info(pid, %Task{} = task, opts \\ task_opts_default())
      when is_pid(pid) and is_struct(task),
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
  @spec invalidate(pid) :: any
  def invalidate(pid) when is_pid(pid), do: declare_and_run(pid, {"invalidate", []})

  @spec invalidate(pid, Task.t(), task_opts()) :: any
  def invalidate(pid, %Task{} = task, opts \\ task_opts_default())
      when is_pid(pid) and is_struct(task),
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
  @spec kill(pid, String.t()) :: any
  def kill(pid, query) when is_pid(pid) and is_binary(query),
    do: declare_and_run(pid, {"kill", [query: query]})

  @spec kill(pid, binary, Task.t(), task_opts()) :: any
  def kill(pid, query, %Task{} = task, opts \\ task_opts_default())
      when is_pid(pid) and is_binary(query) and is_struct(task),
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
  @spec let(pid, String.t(), String.t()) :: any
  def let(pid, key, value) when is_pid(pid) and is_binary(key) and is_binary(value),
    do: declare_and_run(pid, {"let", [key: key, value: value]})

  def let(pid, key, value, %Task{} = task, opts \\ task_opts_default())
      when is_pid(pid) and is_binary(key) and is_binary(value) and is_struct(task),
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
  @spec live(pid, String.t()) :: any
  def live(pid, table) when is_pid(pid) and is_binary(table),
    do: declare_and_run(pid, {"live", [table: table]})

  @spec live(pid, binary, Task.t(), task_opts()) :: any
  def live(pid, table, %Task{} = task, opts \\ task_opts_default())
      when is_pid(pid) and is_binary(table) and is_struct(task),
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
  @spec modify(pid, String.t(), list(map() | struct())) :: any
  def modify(pid, table, payload)
      when is_pid(pid) and is_binary(table) and is_list(payload),
      do: declare_and_run(pid, {"modify", [table: table, payload: payload]})

  @spec modify(pid, String.t(), list(map() | struct()), Task.t(), task_opts()) :: any
  def modify(pid, table, payload, %Task{} = task, opts \\ task_opts_default())
      when is_pid(pid) and is_binary(table) and is_list(payload) and is_struct(task),
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
  @spec ping(pid) :: any
  def ping(pid) when is_pid(pid), do: declare_and_run(pid, {"ping", []})

  @spec ping(pid, Task.t(), task_opts()) :: any
  def ping(pid, %Task{} = task, opts \\ task_opts_default())
      when is_pid(pid) and is_struct(task),
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
  @spec select(pid, String.t()) :: any
  def select(pid, query) when is_pid(pid) and is_binary(query),
    do: declare_and_run(pid, {"select", [query: query]})

  @spec select(pid, String.t(), Task.t(), task_opts()) :: any
  def select(pid, query, %Task{} = task, opts \\ task_opts_default())
      when is_pid(pid) and is_binary(query) and is_struct(task),
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
  @spec signup(pid, map | struct) :: any
  def signup(pid, payload) when is_pid(pid) and (is_map(payload) or is_struct(payload)),
    do: declare_and_run(pid, {"signup", [payload: payload]})

  @spec signup(pid, map | struct, Task.t(), task_opts()) :: any
  def signup(pid, payload, %Task{} = task, opts \\ task_opts_default())
      when is_pid(pid) and (is_map(payload) or is_struct(payload)) and is_struct(task),
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
  @spec update(pid, String.t(), map() | struct()) :: any
  def update(pid, table, payload)
      when (is_pid(pid) and is_binary(table) and is_map(payload)) or is_struct(payload),
      do: declare_and_run(pid, {"update", [table: table, payload: payload]})

  @spec update(pid, String.t(), map | struct, Task.t(), task_opts()) :: any
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
