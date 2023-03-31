defmodule SurrealEx.Helpers do
  @doc """
    Converts a map to a keyword list.

    ## Examples

        iex> SurrealEx.Helpers.map_to_keyword(%{a: 1, b: 2})
        [a: 1, b: 2]
  """
  @spec map_to_keyword(map :: map()) :: keyword()
  def map_to_keyword(map) do
    map
    |> Enum.map(fn {k, v} -> {k, v} end)
    |> List.flatten()
  end

  @doc """
    Converts a struct to a keyword list.

    ## Examples

        iex> SurrealEx.Helpers.struct_to_keyword(%{a: 1, b: 2})
        [a: 1, b: 2]
  """
  @spec struct_to_keyword(atom | struct) :: keyword
  def struct_to_keyword(struct) do
    struct
    |> Map.from_struct()
    |> map_to_keyword()
  end
end
