defmodule SurrealEx.Supervisor do
  use Supervisor

  alias SurrealEx.Types.DriverOpts
  alias SurrealEx.Types.PoolOpts

  @doc """
    This is the entry point for the SurrealEx library. It provides a simple
    API for connecting to SurrealDB and executing queries.

    ## Examples

        iex> {:ok, pid} = SurrealEx.Supervisor.start_link(size: 3, singleton?: false, children: [[singleton?: false], [singleton?: false], [singleton?: false]])
        iex> pid |> Process.alive?
        true

        iex> {:ok, pid} = SurrealEx.Supervisor.start_link(size: 3, singleton?: false, children: [[singleton?: false], [singleton?: false], [singleton?: false]])
        iex> pid |> Supervisor.count_children
        %{active: 3, specs: 3, supervisors: 0, workers: 3}
  """
  @spec start_link(opts :: PoolOpts.t()) ::
          Supervisor.on_start()
  def start_link(opts \\ PoolOpts.default()) do
    opts =
      Keyword.merge(
        PoolOpts.default(),
        opts
      )

    initialization_options = if Keyword.get(opts, :singleton?), do: [name: __MODULE__], else: []

    Supervisor.start_link(
      __MODULE__,
      opts,
      initialization_options
    )
  end

  @opaque supervisor_on_init_return_type ::
            {:ok,
             {Supervisor.sup_flags(),
              [Supervisor.child_spec() | (old_erlang_child_spec :: :supervisor.child_spec())]}}

  @impl true
  @spec init(keyword()) :: supervisor_on_init_return_type()
  def init(initial_state) do
    children =
      for i <- 1..Keyword.get(initial_state, :size) do
        initial_state_for_children =
          if is_nil(Keyword.get(initial_state, :children) |> Enum.at(i)),
            do: DriverOpts.default(),
            else: Keyword.get(initial_state, :children) |> Enum.at(i)

        Supervisor.child_spec({SurrealEx.Instance, initial_state_for_children}, id: i)
      end

    Supervisor.init(children, strategy: :one_for_one)
  end
end
