defmodule SurrealEx.Operations do
  @moduledoc """
    This module is a behavior to ensure every module implementing it have the
    same capability of doing the operations avaialble in Surreal DB.
  """

  defmacro __using__(_opts) do
    quote do
      @behaviour SurrealEx.Operations
    end
  end

  @type common_response :: any()

  @callback ping(pid()) :: common_response()
  @callback ping(pid(), Task.t(), task_opts :: keyword()) :: term()

  @callback use(pid(), namespace :: String.t(), database :: String.t()) ::
              common_response()
  @callback use(
              pid(),
              namespace :: String.t(),
              database :: String.t(),
              Task.t(),
              task_opts :: keyword
            ) ::
              term()

  @callback info(pid()) :: common_response()
  @callback info(pid(), Task.t(), task_opts :: keyword()) :: term()

  @type sign_up_payload :: %{
          NS: String.t(),
          DB: String.t(),
          SC: String.t(),
          email: String.t(),
          pass: String.t()
        }
  @callback sign_up(pid(), sign_up_payload()) :: common_response()
  @callback sign_up(pid(), sign_up_payload(), Task.t(), task_opts :: keyword()) ::
              term()

  # REFERENCE: https://github.com/surrealdb/surrealdb.js/blob/ce949aeddd2b451b3b7b473705e62fbbc58e095b/src/index.ts#L72
  @type sign_in_payload :: %{
          NS: String.t(),
          DB: String.t(),
          user: String.t(),
          pass: String.t()
        }
  @callback sign_in(pid(), sign_in_payload()) :: common_response()
  @callback sign_in(pid(), sign_in_payload(), Task.t(), task_opts :: keyword()) ::
              term()

  @callback invalidate(pid()) :: common_response()
  @callback invalidate(pid(), Task.t(), task_opts :: keyword()) :: term()

  @callback authenticate(pid(), token :: String.t()) :: common_response()
  @callback authenticate(pid(), token :: String.t(), Task.t(), task_opts :: keyword()) :: term()

  @callback live(pid(), table :: String.t()) :: common_response()
  @callback live(pid(), table :: String.t(), Task.t(), task_opts :: keyword()) :: term()

  @callback kill(pid(), query :: any()) :: common_response()
  @callback kill(pid(), query :: any(), Task.t(), task_opts :: keyword()) :: term()

  @callback let(pid(), key :: String.t(), value :: String.t()) :: common_response()
  @callback let(pid(), key :: String.t(), value :: String.t(), Task.t(), task_opts :: keyword()) ::
              term()

  @callback query(pid(), query :: String.t(), values :: map() | struct()) ::
              common_response()
  @callback query(
              pid(),
              query :: String.t(),
              values :: map() | struct(),
              Task.t(),
              task_opts :: keyword()
            ) ::
              term()

  @callback select(pid(), table :: String.t()) :: common_response()
  @callback select(pid(), table :: String.t(), Task.t(), task_opts :: keyword()) :: term()

  @callback create(pid(), table :: String.t(), values :: map() | struct()) ::
              common_response()
  @callback create(
              pid(),
              table :: String.t(),
              values :: map() | struct(),
              Task.t(),
              task_opts :: keyword()
            ) ::
              term()

  @callback update(pid(), table :: String.t(), values :: map() | struct()) ::
              common_response()
  @callback update(
              pid(),
              table :: String.t(),
              values :: map() | struct(),
              Task.t(),
              task_opts :: keyword()
            ) ::
              term()

  @callback change(pid(), table :: String.t(), values :: map() | struct()) ::
              common_response()
  @callback change(
              pid(),
              table :: String.t(),
              values :: map() | struct(),
              Task.t(),
              task_opts :: keyword()
            ) ::
              term()

  @callback modify(pid(), table :: String.t(), values :: list(map() | struct())) ::
              common_response()
  @callback modify(
              pid(),
              table :: String.t(),
              values :: list(map() | struct()),
              Task.t(),
              task_opts :: keyword()
            ) ::
              term()

  @callback delete(pid(), table :: String.t()) :: common_response()
  @callback delete(pid(), table :: String.t(), Task.t(), task_opts :: keyword()) :: term()
end
