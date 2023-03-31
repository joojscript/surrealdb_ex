defmodule SurrealEx.SupervisorTest do
  use ExUnit.Case, async: true

  doctest SurrealEx.Supervisor

  alias SurrealEx.Supervisor

  test "start_link/0" do
    assert {:ok, pid} = Supervisor.start_link(size: 1, singleton?: false)
    assert pid |> Process.alive?()
  end

  test "start_link/0 with children" do
    assert {:ok, pid} =
             Supervisor.start_link(
               size: 3,
               singleton?: false,
               children: [[singleton?: false], [singleton?: false], [singleton?: false]]
             )

    assert pid |> Process.alive?()
  end

  test "start_link/0 with children and singleton" do
    assert {:ok, pid} =
             Supervisor.start_link(
               size: 3,
               singleton?: true,
               children: [[singleton?: false], [singleton?: false], [singleton?: false]]
             )

    assert pid |> Process.alive?()

    # Remove singleton instance so no conflicts on __MODULE__ name are created.
    Process.exit(pid, :kill)
  end

  test "correctly restart children" do
    assert {:ok, pid} =
             Supervisor.start_link(
               size: 3,
               singleton?: false,
               children: [[singleton?: false], [singleton?: false], [singleton?: false]]
             )

    assert pid |> Elixir.Supervisor.count_children() == %{
             active: 3,
             specs: 3,
             supervisors: 0,
             workers: 3
           }

    # Kill a child
    assert {_child_index, child_pid, :worker, _child_module} =
             Elixir.Supervisor.which_children(pid) |> Enum.at(0)

    # Starts monitoring the child
    Process.monitor(child_pid)

    Process.exit(child_pid, :kill)

    # Wait for child to restart
    assert_receive {:DOWN, _, :process, ^child_pid, _}

    # Check that the child has been restarted
    assert pid |> Elixir.Supervisor.count_children() == %{
             active: 3,
             specs: 3,
             supervisors: 0,
             workers: 3
           }
  end
end
