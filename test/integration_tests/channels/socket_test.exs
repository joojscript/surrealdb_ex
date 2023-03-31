defmodule SurrealEx.Channels.SocketTest do
  use ExUnit.Case, async: true

  import Mock

  alias SurrealEx.Channels.Socket

  # setup_with_mocks([
  #   {WebSockex, [:passthrough], [cast: fn _, _ -> :ok end]}
  # ]) do
  #   {:ok, []}
  # end

  @socket_connection_opts [
    hostname: "192.168.0.114",
    port: 8002,
    database: "default",
    namespace: "default",
    username: "root",
    password: "root"
  ]

  @tag integration: true
  test "start_link/1" do
    assert {:ok, _pid} = Socket.start_link(@socket_connection_opts)
  end

  @tag integration: true
  test "stop/1" do
    assert {:ok, pid} = Socket.start_link(@socket_connection_opts)
    assert :ok = Socket.stop(pid)
  end

  @tag integration: true
  test "sign_in/2" do
    {:ok, pid} = SurrealEx.Channels.Socket.start_link(@socket_connection_opts)

    assert :ok ==
             SurrealEx.Channels.Socket.sign_in(pid, %{
               "user" => "root",
               "pass" => "root",
               "NS" => "default",
               "DB" => "default"
             })
  end
end
