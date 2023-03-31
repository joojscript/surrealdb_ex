defmodule SurrealEx.InstanceTest do
  use ExUnit.Case, async: true

  doctest SurrealEx.Instance

  alias SurrealEx.Instance

  test "start_link/0" do
    assert {:ok, pid} = Instance.start_link()
    assert pid |> Process.alive?()
  end
end
