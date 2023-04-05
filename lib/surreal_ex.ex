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
  alias SurrealEx.Socket

  defdelegate start_link(), to: Socket
  defdelegate start_link(opts), to: Socket

  defdelegate stop(pid), to: Socket

  defdelegate signin(pid, payload), to: Socket
  defdelegate signin(pid, payload, task), to: Socket
  defdelegate signin(pid, payload, task, opts), to: Socket

  defdelegate query(pid, query, payload), to: Socket
  defdelegate query(pid, query, payload, task), to: Socket
  defdelegate query(pid, query, payload, task, opts), to: Socket

  defdelegate use(pid, namespace, database), to: Socket
  defdelegate use(pid, namespace, database, task), to: Socket
  defdelegate use(pid, namespace, database, task, opts), to: Socket

  defdelegate authenticate(pid, token), to: Socket
  defdelegate authenticate(pid, token, task), to: Socket
  defdelegate authenticate(pid, token, task, opts), to: Socket

  defdelegate change(pid, table, payload), to: Socket
  defdelegate change(pid, table, payload, task), to: Socket
  defdelegate change(pid, table, payload, task, opts), to: Socket

  defdelegate create(pid, table, payload), to: Socket
  defdelegate create(pid, table, payload, task), to: Socket
  defdelegate create(pid, table, payload, task, opts), to: Socket

  defdelegate delete(pid, table), to: Socket
  defdelegate delete(pid, table, task), to: Socket
  defdelegate delete(pid, table, task, opts), to: Socket

  defdelegate info(pid), to: Socket
  defdelegate info(pid, task), to: Socket
  defdelegate info(pid, task, opts), to: Socket

  defdelegate invalidate(pid), to: Socket
  defdelegate invalidate(pid, task), to: Socket
  defdelegate invalidate(pid, task, opts), to: Socket

  defdelegate kill(pid, query), to: Socket
  defdelegate kill(pid, query, task), to: Socket
  defdelegate kill(pid, query, task, opts), to: Socket

  defdelegate let(pid, key, value), to: Socket
  defdelegate let(pid, key, value, task), to: Socket
  defdelegate let(pid, key, value, task, opts), to: Socket

  defdelegate live(pid, table), to: Socket
  defdelegate live(pid, table, task), to: Socket
  defdelegate live(pid, table, task, opts), to: Socket

  defdelegate modify(pid, table, payload), to: Socket
  defdelegate modify(pid, table, payload, task), to: Socket
  defdelegate modify(pid, table, payload, task, opts), to: Socket

  defdelegate ping(pid), to: Socket
  defdelegate ping(pid, task), to: Socket
  defdelegate ping(pid, task, opts), to: Socket

  defdelegate select(pid, query), to: Socket
  defdelegate select(pid, query, task), to: Socket
  defdelegate select(pid, query, task, opts), to: Socket

  defdelegate signup(pid, payload), to: Socket
  defdelegate signup(pid, payload, task), to: Socket
  defdelegate signup(pid, payload, task, opts), to: Socket

  defdelegate update(pid, table, payload), to: Socket
  defdelegate update(pid, table, payload, task), to: Socket
  defdelegate update(pid, table, payload, task, opts), to: Socket
end
