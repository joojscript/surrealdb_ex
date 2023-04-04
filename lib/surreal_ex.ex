defmodule SurrealEx do
  @moduledoc """
    Welcome to the Elixir driver for SurrealDB! This library allows you to
    connect to SurrealDB, a highly-scalable, distributed NoSQL database designed
    for modern applications. With the Elixir driver, you can seamlessly
    integrate SurrealDB into your Elixir projects and enjoy the benefits of a
    robust, cloud-native database.

    The Elixir driver for SurrealDB provides a simple, yet powerful API for
    working with SurrealDB. It leverages the Erlang/Elixir ecosystem to provide
    a performant and fault-tolerant connection to SurrealDB, and supports a wide
    range of operations such as querying, inserting, updating, and deleting data.

    This documentation provides a comprehensive guide to using the Elixir driver
    for SurrealDB. It covers everything from installation and setup, to advanced
    usage scenarios and troubleshooting tips. Whether you are a seasoned Elixir
    developer or new to the language, this documentation will help you get up
    and running with SurrealDB in no time.

    We hope you enjoy using the Elixir driver for SurrealDB and welcome your
    feedback and contributions. Happy coding!
  """
  alias SurrealEx.Operations
  alias SurrealEx.Socket

  @after_compile __MODULE__
  @delegate_functions Operations.behaviour_info(:callbacks)

  def __after_compile__(_env, _bytecode) do
    for {function_name, arity} <- @delegate_functions do
      formatted_function_name = "&#{function_name}/#{arity}"

      quote do
        defdelegate unquote(formatted_function_name), to: Socket
      end
    end
  end

  @spec start_link(Socket.socket_opts()) :: {:ok, pid()} | {:error, any()}
  def start_link(opts) do
    Socket.start_link(opts)
  end
end
