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

  @callback ping(pid()) :: :ok | {:error, term()}

  @callback use(pid(), namespace :: String.t(), database :: String.t()) ::
              :ok | {:error, term()}

  @callback info(pid()) :: :ok | {:error, term()}

  @type sign_up_payload :: []
  @callback sign_up(pid(), sign_up_payload()) :: :ok | {:error, term()}

  # REFERENCE: https://github.com/surrealdb/surrealdb.js/blob/ce949aeddd2b451b3b7b473705e62fbbc58e095b/src/index.ts#L72
  @type sign_in_payload :: [
          NS: String.t(),
          DB: String.t(),
          user: String.t(),
          pass: String.t()
        ]
  @callback sign_in(pid(), sign_in_payload()) :: :ok | {:error, term()}

  @callback invalidate(pid()) :: :ok | {:error, term()}
  @callback authenticate(pid(), token :: String.t()) :: :ok | {:error, term()}
  @callback live(pid(), table :: String.t()) :: :ok | {:error, term()}
  @callback kill(pid(), query :: any()) :: :ok | {:error, term()}
  @callback let(pid(), key :: String.t(), value :: String.t()) :: :ok | {:error, term()}

  @callback query(pid(), query :: String.t(), values :: map() | struct()) ::
              :ok | {:error, term()}

  @callback select(pid(), table :: String.t()) :: :ok | {:error, term()}

  @callback create(pid(), table :: String.t(), values :: map() | struct()) ::
              :ok | {:error, term()}

  @callback update(pid(), table :: String.t(), values :: map() | struct()) ::
              :ok | {:error, term()}

  @callback change(pid(), table :: String.t(), values :: map() | struct()) ::
              :ok | {:error, term()}

  @callback modify(pid(), table :: String.t(), values :: map() | struct()) ::
              :ok | {:error, term()}

  @callback delete(pid(), table :: String.t()) :: :ok | {:error, term()}
end
