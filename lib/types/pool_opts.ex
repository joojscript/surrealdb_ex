defmodule SurrealEx.Types.PoolOpts do
  alias SurrealEx.Types.DriverOpts

  @type t :: [
          {:size, non_neg_integer()},
          {:max_overflow, non_neg_integer()},
          {:timeout, non_neg_integer()},
          {:pool_timeout, non_neg_integer()},
          {:pool_size, non_neg_integer()},
          {:singleton?, boolean()},
          {:children, [DriverOpts.t()]}
        ]

  defstruct [
    :size,
    :max_overflow,
    :timeout,
    :pool_timeout,
    :pool_size,
    :singleton?,
    :children
  ]

  @spec default :: __MODULE__.t()
  def default,
    do: [
      size: 10,
      max_overflow: 10,
      timeout: 5000,
      pool_timeout: 5000,
      pool_size: 10,
      singleton?: true,
      children: []
    ]
end
