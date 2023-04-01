defmodule SurrealEx.Channels.SocketTest do
  use ExUnit.Case, async: true

  import Mock

  alias SurrealEx.Channels.Socket

  defp generate_fake_gen_server do
    {pid, _ref} =
      Process.spawn(
        fn ->
          receive do
          end
        end,
        [:monitor]
      )

    pid
  end

  setup_with_mocks([
    {WebSockex, [:passthrough],
     [
       cast: fn _, _ -> :ok end,
       start_link: fn _, _, _ ->
         {:ok, generate_fake_gen_server()}
       end
     ]}
  ]) do
    {:ok, []}
  end

  @tag integration: true
  test "start_link/1" do
    assert {:ok, _pid} = Socket.start_link()
  end

  @tag integration: true
  test "stop/1" do
    assert {:ok, pid} = Socket.start_link()
    assert :ok = Socket.stop(pid)
  end

  @tag integration: true
  test "sign_in/2" do
    {:ok, pid} = Socket.start_link()

    assert :ok ==
             Socket.sign_in(pid, %{
               "user" => "root",
               "pass" => "root",
               "NS" => "default",
               "DB" => "default"
             })
  end

  @tag integration: true
  test "query/3" do
    {:ok, pid} = Socket.start_link()

    assert :ok ==
             Socket.query(pid, "SELECT * FROM type::table($table)", table: "users")
  end

  @tag integration: true
  test "use/3" do
    {:ok, pid} = Socket.start_link()

    assert :ok == Socket.use(pid, "default", "default")
  end

  @tag integration: true
  test "authenticate/2" do
    {:ok, pid} = Socket.start_link()

    assert :ok ==
             Socket.authenticate(
               pid,
               "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJTdXJyZWFsREIiLCJpYXQiOjE1MTYyMzkwMjIsIm5iZiI6MTUxNjIzOTAyMiwiZXhwIjoxODM2NDM5MDIyLCJOUyI6InRlc3QiLCJEQiI6InRlc3QiLCJTQyI6InVzZXIiLCJJRCI6InVzZXI6dG9iaWUifQ.N22Gp9ze0rdR06McGj1G-h2vu6a6n9IVqUbMFJlOxxA"
             )
  end

  @tag integration: true
  test "change/3" do
    {:ok, pid} = Socket.start_link()

    assert :ok == Socket.change(pid, "users:jhonny", %{"name" => "John"})
  end

  @tag integration: true
  test "create/3" do
    {:ok, pid} = Socket.start_link()

    assert :ok == Socket.create(pid, "users", %{"name" => "John"})
  end

  @tag integration: true
  test "delete/3" do
    {:ok, pid} = Socket.start_link()

    assert :ok == Socket.delete(pid, "users:jhonny")
  end

  @tag integration: true
  test "info/1" do
    {:ok, pid} = Socket.start_link()

    assert :ok == Socket.info(pid)
  end

  @tag integration: true
  test "invalidate/1" do
    {:ok, pid} = Socket.start_link()

    assert :ok == Socket.invalidate(pid)
  end

  @tag integration: true
  test "kill/2" do
    {:ok, pid} = Socket.start_link()

    assert :ok == Socket.kill(pid, "users:jhonny")
  end

  @tag integration: true
  test "let/3" do
    {:ok, pid} = Socket.start_link()

    assert :ok == Socket.let(pid, "user_name", "John")
  end

  @tag integration: true
  test "live/2" do
    {:ok, pid} = Socket.start_link()

    assert :ok == Socket.live(pid, "users")
  end

  @tag integration: true
  test "modify/3" do
    {:ok, pid} = Socket.start_link()

    assert :ok ==
             Socket.modify(pid, "users", [
               %{op: "replace", path: "/created_at", value: DateTime.utc_now() |> to_string()}
             ])
  end

  @tag integration: true
  test "ping/1" do
    {:ok, pid} = Socket.start_link()

    assert :ok == Socket.ping(pid)
  end

  @tag integration: true
  test "select/2" do
    {:ok, pid} = Socket.start_link()

    assert :ok == Socket.select(pid, "users")
  end

  @tag integration: true
  test "sign_up/2" do
    {:ok, pid} = Socket.start_link()

    assert :ok == Socket.sign_up(pid, user: "root", pass: "root")
  end

  @tag integration: true
  test "update/3" do
    {:ok, pid} = Socket.start_link()

    assert :ok == Socket.update(pid, "users:jhonny", name: "John")
  end
end
