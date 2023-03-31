defmodule SurrealEx.Instance do
  use GenServer

  alias SurrealEx.Types.DriverOpts

  @doc """
    This is the entry point for the SurrealEx library. It provides a simple
    API for connecting to SurrealDB and executing queries.

    ## Examples

        iex> {:ok, pid} = SurrealEx.Instance.start_link()
        iex> pid |> Process.alive?
        true
  """
  @spec start_link(opts :: DriverOpts.t()) ::
          GenServer.on_start()
  def start_link(opts \\ DriverOpts.default()) do
    opts =
      Keyword.merge(
        DriverOpts.default(),
        opts
      )

    initialization_options = if Keyword.get(opts, :singleton?), do: [name: __MODULE__], else: []

    GenServer.start_link(
      __MODULE__,
      opts,
      initialization_options
    )
  end

  def init(initial_state \\ []), do: {:ok, initial_state}
end
