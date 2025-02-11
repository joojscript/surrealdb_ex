
<h1 align="center">
  <img src="./.github/assets/logo.png" alt="Surreal DB Elixir" height="200" />
  <br />
  SurrealDB EX
</h1>
  <!---->  
  
  <br />
 <p align="center">
  <a href="#Installation">Installation</a> •
  <a href="#Configuration">Configuration</a> •
  <a href="#Usage">Usage</a> •
  <a href="#Documentation">Documentation</a>
</p>

  <div align="center">
    <img alt="made_with" src="https://img.shields.io/badge/MADE%20WITH-ELIXIR-8700ff?style=for-the-badge&logo=elixir" />
    <img alt="build_status" src="https://img.shields.io/github/actions/workflow/status/joojscript/surrealdb_ex/ci.yml?style=for-the-badge&color=8700ff" />
    <img alt="hex_downloads" src="https://img.shields.io/hexpm/dt/surrealdb_ex?style=for-the-badge&color=8700ff" />
    <img alt="open_issues" src="https://img.shields.io/github/issues-raw/joojscript/surrealdb_ex?style=for-the-badge&color=8700ff" />
    <img alt="version" src="https://img.shields.io/hexpm/v/surrealdb_ex?color=8700ff&style=for-the-badge" />
  </div>
  
  <br/>

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

## Installation

The package can be installed by adding `surrealdb_ex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:surrealdb_ex, "~> 0.0.2"}
  ]
end
```

## Configuration

You can set up the necessary configuration for the module under your `config/*.exs` file, in the following format:

```elixir
import Config

config :surrealdb_ex,
  connection_config: [
    hostname: "192.168.0.114",
    port: 8002,
    username: "root",
    password: "root",
    database: "default",
    namespace: "default"
  ]
```

## Usage

This driver is menat to have a easy-to-use and [design compliant](https://surrealdb.com/docs/integration/libraries/nodejs) API, here are some examples:

|   | NodeJS (official supported library)   | Elixir Driver for Surreal DB  |
|---|---|---|
| `QUERYING` | ```await db.select("person");``` | ```SurrealEx.select("person")``` |
| `INSERTING`  | ```await db.create("person", {title: 'Founder & CEO', name: 'Tobie', marketing: true});```  | ```SurrealEx.create(pid, "person", %{title: "Founder & CEO", name: "Tobie", marketing: true})``` |
| `UPDATING`  | ```await db.change("person:jaime", {marketing: true});```  | ```SurrealEx.change(pid, "person:jaime", %{marketing: true})``` |

And so much more! Basically every single function available on the official library for NodeJS*, is supported by this driver.

*If there are any other implementations with different and/or better approaches, feel free to open a request for it to be added.

## Additional Features to take note

All the functions available are following the format of the NodeJs client library, including the function signatures.

All functions are synchronous, if you want to run asynchronously, every functions have alternate signatures using **Tasks**, so you can control how the result will be handled when it comes. But **beware** not to fall in *deadlocks*.

- Quick Example:

```elixir
  # Synchronously invoked.
  def update(pid, table, payload)

  # Accepts a %Task{} struct, which will handle the result, also some opts 
  # regarding the execution of this task. See more on the docs.
  def update(pid, table, payload, task, opts)
```

## Running tests

You can run the full suite of tests by running the following command:

```bash
mix test
```

But it is higly recomended to `exclude` all the **integration** tests, as they
are going to try to connect to an actual Surreal DB instance. In the other hand,
if you have it running (please, take note that it will insert dummy data for testing,
be careful). You can just override integration test configs:

```elixir
config :surrealdb_ex,
  test_database_config: [
    hostname: "localhost",
    port: 8000,
    username: "root",
    password: "root",
    database: "default",
    namespace: "default"
  ]
```

## Documentation

Documentation can be found on [HexDocs](https://hexdocs.pm/surrealdb_ex).
Also, the package definition on Hex.pm, can be found [here](https://hex.pm/packages/surrealdb_ex)
