defmodule SurrealEx.Macros do
  defmacro __using__(_args) do
    quote do
      defguard is_process_identifier(pid) when is_pid(pid) or is_atom(pid)
      defguard is_payload_type(target) when is_map(target) or is_struct(target)
    end
  end
end
