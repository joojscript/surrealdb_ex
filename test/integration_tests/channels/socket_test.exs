defmodule SurrealEx.SocketTest do
  use ExUnit.Case, async: true

  require Logger

  alias SurrealEx.Socket

  @test_database_config Application.compile_env(:surrealdb_ex, :test_database_config,
                          hostname: "localhost",
                          port: 8000,
                          username: "root",
                          password: "root",
                          database: "default",
                          namespace: "default"
                        )

  defp setup_test_database(socket_pid) do
    Logger.info("Setting up test database")

    sample_scope_creation_query = """
      DEFINE SCOPE allusers
      -- the JWT session will be valid for 14 days
      SESSION 14d
      -- The optional SIGNUP clause will be run when calling the signup method for this scope
      -- It is designed to create or add a new record to the database.
      -- If set, it needs to return a record or a record id
      -- The variables can be passed in to the signin method
      SIGNUP ( CREATE user SET user = $user, pass = crypto::argon2::generate($pass) )
      -- The optional SIGNIN clause will be run when calling the signin method for this scope
      -- It is designed to check if a record exists in the database.
      -- If set, it needs to return a record or a record id
      -- The variables can be passed in to the signin method
      SIGNIN ( SELECT * FROM user WHERE user = $user AND crypto::argon2::compare(pass, $pass) )
      -- this optional clause will be run when calling the signup method for this scope
    """

    # Get from the test args:
    database = Keyword.get(@test_database_config, :database)
    namespace = Keyword.get(@test_database_config, :namespace)
    username = Keyword.get(@test_database_config, :username)
    password = Keyword.get(@test_database_config, :password)

    # Select namespace and database:
    assert {:ok, _} = Socket.use(socket_pid, namespace, database)

    # Sign in as root:
    assert {:ok, _} =
             Socket.signin(socket_pid, %{
               "user" => username,
               "pass" => password
             })

    # Create a sample scope:
    assert {:ok, _} = Socket.query(socket_pid, sample_scope_creation_query, %{})
    Logger.info("Test database setup complete")
  end

  setup_all do
    # Create a simple connection to the database to make the first configuration
    {:ok, socket_pid} = Socket.start_link(@test_database_config)
    setup_test_database(socket_pid)

    {:ok, agent_pid} = Agent.start_link(fn -> @test_database_config end)
    {:ok, %{agent_pid: agent_pid}}
  end

  setup context do
    {:ok, socket_pid} = Socket.start_link(@test_database_config)

    # Authenticate:
    username = Keyword.get(@test_database_config, :username)
    password = Keyword.get(@test_database_config, :password)
    Socket.signin(socket_pid, %{user: username, pass: password})

    # Select namespace and database:
    namespace = Keyword.get(@test_database_config, :namespace)
    database = Keyword.get(@test_database_config, :database)
    Socket.use(socket_pid, namespace, database)

    {:ok, Map.merge(%{socket_pid: socket_pid}, context)}
  end

  @tag integration: true
  test "start_link/1" do
    assert {:ok, _pid} = Socket.start_link(@test_database_config)
  end

  @tag integration: true
  test "stop/1", %{socket_pid: socket_pid} do
    assert :ok = Socket.stop(socket_pid)
  end

  @tag integration: true
  test "signin/2", %{socket_pid: socket_pid} do
    assert {:ok, _} =
             Socket.signin(socket_pid, %{
               "user" => "root",
               "pass" => "root"
             })
  end

  @tag integration: true
  test "query/3", %{socket_pid: socket_pid} do
    assert {:ok, %{"result" => [%{"status" => "OK"}]}} =
             Socket.query(socket_pid, "SELECT * FROM type::table($table)", %{table: "users"})
  end

  @tag integration: true
  test "use/3", %{socket_pid: socket_pid} do
    # Select namespace:
    namespace = Keyword.get(@test_database_config, :namespace)
    database = Keyword.get(@test_database_config, :database)
    assert {:ok, _} = Socket.use(socket_pid, namespace, database)
  end

  @tag integration: true
  test "authenticate/2", %{socket_pid: socket_pid, agent_pid: agent_pid} do
    # Sign up to the database
    assert {:ok, %{"result" => jwt_token}} =
             Socket.signup(
               socket_pid,
               %{
                 DB: "test",
                 NS: "test",
                 user: "root",
                 pass: "root",
                 SC: "allusers"
               }
             )

    assert Agent.update(
             agent_pid,
             fn config ->
               Keyword.merge(config, jwt_token: jwt_token)
             end
           ) == :ok

    assert {:ok, _} = Socket.authenticate(socket_pid, jwt_token)
  end

  @tag integration: true
  # Get authentication token from previous test cases
  test "change/3", %{socket_pid: socket_pid, agent_pid: agent_pid} do
    assert {:ok, _} = Socket.change(socket_pid, "users:jhonny", %{"name" => "John"})
  end

  @tag integration: true
  test "create/3", %{socket_pid: socket_pid} do
    assert {:ok, _} = Socket.create(socket_pid, "users", %{"name" => "John"})
  end

  @tag integration: true
  test "delete/3", %{socket_pid: socket_pid} do
    assert {:ok, _} = Socket.delete(socket_pid, "users:jhonny")
  end

  @tag integration: true
  test "info/1", %{socket_pid: socket_pid} do
    assert {:ok, _} = Socket.info(socket_pid)
  end

  @tag integration: true
  test "invalidate/1", %{socket_pid: socket_pid} do
    assert {:ok, _} = Socket.invalidate(socket_pid)
  end

  @tag integration: true
  # WARNING: Fot now it is failing, it should be fixed/stabilized in the next release
  # REFERENCE: https://surrealdb.com/features#surrealql (under "Live queries and record changes")
  test "kill/2", %{socket_pid: socket_pid} do
    assert {:error, _} =
             Socket.kill(socket_pid, "1986cc4e-340a-467d-9290-de81583267a2")
  end

  @tag integration: true
  test "let/3", %{socket_pid: socket_pid} do
    assert {:ok, _} = Socket.let(socket_pid, "user_name", "John")
  end

  @tag integration: true
  test "live/2", %{socket_pid: socket_pid} do
    assert {:ok, _} = Socket.live(socket_pid, "users")
  end

  @tag integration: true
  test "modify/3", %{socket_pid: socket_pid} do
    assert {:ok, _} =
             Socket.modify(socket_pid, "users", [
               %{op: "replace", path: "/created_at", value: DateTime.utc_now() |> to_string()}
             ])
  end

  @tag integration: true
  test "ping/1", %{socket_pid: socket_pid} do
    assert {:ok, _} = Socket.ping(socket_pid)
  end

  @tag integration: true
  test "select/2", %{socket_pid: socket_pid} do
    assert {:ok, _} = Socket.select(socket_pid, "users")
  end

  @tag integration: true
  test "signup/2", %{socket_pid: socket_pid} do
    username = Keyword.get(@test_database_config, :username)
    password = Keyword.get(@test_database_config, :password)
    database = Keyword.get(@test_database_config, :database)
    namespace = Keyword.get(@test_database_config, :namespace)

    assert {:ok, _} =
             Socket.signup(socket_pid, %{
               user: username,
               pass: password,
               SC: "allusers",
               DB: database,
               NS: namespace
             })
  end

  @tag integration: true
  test "update/3", %{socket_pid: socket_pid} do
    assert {:ok, _} = Socket.update(socket_pid, "users:jhonny", %{name: "John"})
  end
end
