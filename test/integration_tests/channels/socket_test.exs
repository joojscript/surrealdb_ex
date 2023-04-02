defmodule SurrealEx.Channels.SocketTest do
  use ExUnit.Case, async: true

  alias SurrealEx.Channels.Socket

  @test_database_config Application.compile_env(:surreal_ex, :test_database_config,
                          hostname: "localhost",
                          port: 8000,
                          username: "root",
                          password: "root",
                          database: "default",
                          namespace: "default"
                        )

  @tag integration: true
  test "start_link/1" do
    assert {:ok, _pid} = Socket.start_link(@test_database_config)
  end

  @tag integration: true
  test "stop/1" do
    assert {:ok, pid} = Socket.start_link(@test_database_config)
    assert :ok = Socket.stop(pid)
  end

  # @tag integration: true
  # test "sign_in/2" do
  #   {:ok, pid} = Socket.start_link(@test_database_config)

  #   assert :ok ==
  #            Socket.sign_in(pid, %{
  #              "user" => "root",
  #              "pass" => "root",
  #              "NS" => "default",
  #              "DB" => "default"
  #            })
  # end

  @tag integration: true
  test "query/3" do
    # Start Process:
    {:ok, pid} = Socket.start_link(@test_database_config)

    # Select namespace:
    assert {:ok, _} = Socket.use(pid, "default", "default")

    assert {:ok, %{"result" => [%{"status" => "OK"}]}} =
             Socket.query(pid, "SELECT * FROM type::table($table)", %{table: "users"})
  end

  @tag integration: true
  test "use/3" do
    # Start Process:
    {:ok, pid} = Socket.start_link(@test_database_config)

    # Select namespace:
    assert {:ok, _} = Socket.use(pid, "default", "default")
  end

  # @tag integration: true
  # test "authenticate/2" do
  #   {:ok, pid} = Socket.start_link(@test_database_config)

  #   # Sign up to the database
  #   assert :ok ==
  #            Socket.sign_up(
  #              pid,
  #              %{
  #                NS: "default",
  #                DB: "default",
  #                SC: "user",
  #                email: "info@surrealdb.com",
  #                pass: "123456"
  #              }
  #            )

  #   assert :ok ==
  #            Socket.authenticate(
  #              pid,
  #              "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJTdXJyZWFsREIiLCJpYXQiOjE1MTYyMzkwMjIsIm5iZiI6MTUxNjIzOTAyMiwiZXhwIjoxODM2NDM5MDIyLCJOUyI6ImRlZmF1bHQiLCJEQiI6ImRlZmF1bHQiLCJJRCI6InVzZXI6dG9iaWUifQ.5J-KU53JPyw4yrE8ppsAkyovoH9Cpgq4Mgf_kuiWtWs"
  #            )
  # end

  # @tag integration: true
  # test "change/3" do
  #   # Start Process:
  #   {:ok, pid} = Socket.start_link(@test_database_config)

  #   # Select namespace:
  #   assert {:ok, _} = Socket.use(pid, "default", "default")

  #   assert :ok == Socket.change(pid, "users:jhonny", %{"name" => "John"})
  # end

  # @tag integration: true
  # test "create/3" do
  #   # Start Process:
  #   {:ok, pid} = Socket.start_link(@test_database_config)

  #   # Select namespace:
  #   assert {:ok, _} = Socket.use(pid, "default", "default")

  #   assert :ok == Socket.create(pid, "users", %{"name" => "John"})
  # end

  # @tag integration: true
  # test "delete/3" do
  #   {:ok, pid} = Socket.start_link(@test_database_config)

  #   assert :ok == Socket.delete(pid, "users:jhonny")
  # end

  @tag integration: true
  test "info/1" do
    # Start Process:
    {:ok, pid} = Socket.start_link(@test_database_config)

    # Select namespace:
    assert {:ok, _} = Socket.use(pid, "default", "default")

    assert {:ok, _} = Socket.info(pid)
  end

  @tag integration: true
  test "invalidate/1" do
    # Start Process:
    {:ok, pid} = Socket.start_link(@test_database_config)

    # Select namespace:
    assert {:ok, _} = Socket.use(pid, "default", "default")

    assert {:ok, _} = Socket.invalidate(pid)
  end

  @tag integration: true
  test "kill/2" do
    # Start Process:
    {:ok, pid} = Socket.start_link(@test_database_config)

    # Select namespace:
    assert {:ok, _} = Socket.use(pid, "default", "default")

    assert {:ok, _} = Socket.kill(pid, "users:jhonny")
  end

  @tag integration: true
  test "let/3" do
    # Start Process:
    {:ok, pid} = Socket.start_link(@test_database_config)

    # Select namespace:
    assert {:ok, _} = Socket.use(pid, "default", "default")

    assert {:ok, _} = Socket.let(pid, "user_name", "John")
  end

  @tag integration: true
  test "live/2" do
    # Start Process:
    {:ok, pid} = Socket.start_link(@test_database_config)

    # Select namespace:
    assert {:ok, _} = Socket.use(pid, "default", "default")

    assert {:ok, _} = Socket.live(pid, "users")
  end

  @tag integration: true
  test "modify/3" do
    # Start Process:
    {:ok, pid} = Socket.start_link(@test_database_config)

    # Select namespace:
    assert {:ok, _} = Socket.use(pid, "default", "default")

    assert {:ok, _} =
             Socket.modify(pid, "users", [
               %{op: "replace", path: "/created_at", value: DateTime.utc_now() |> to_string()}
             ])
  end

  @tag integration: true
  test "ping/1" do
    # Start Process:
    {:ok, pid} = Socket.start_link(@test_database_config)

    # Select namespace:
    assert {:ok, _} = Socket.use(pid, "default", "default")

    assert {:ok, _} = Socket.ping(pid)
  end

  @tag integration: true
  test "select/2" do
    # Start Process:
    {:ok, pid} = Socket.start_link(@test_database_config)

    # Select namespace:
    assert {:ok, _} = Socket.use(pid, "default", "default")

    assert {:ok, _} = Socket.select(pid, "users")
  end

  @tag integration: true
  test "sign_up/2" do
    # Start Process:
    {:ok, pid} = Socket.start_link(@test_database_config)

    # Select namespace:
    assert {:ok, _} = Socket.use(pid, "default", "default")

    assert {:ok, _} = Socket.sign_up(pid, %{user: "root", pass: "root"})
  end

  @tag integration: true
  test "update/3" do
    # Start Process:
    {:ok, pid} = Socket.start_link(@test_database_config)

    # Select namespace:
    assert {:ok, _} = Socket.use(pid, "default", "default")

    assert {:ok, _} = Socket.update(pid, "users:jhonny", %{name: "John"})
  end
end
