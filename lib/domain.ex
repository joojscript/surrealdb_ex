defmodule SurrealEx.Domain.SocketOpts do
  @moduledoc """
  Defines the struct for socket options.
  """
  defstruct [
    :hostname,
    :port,
    :namespace,
    :database,
    :username,
    :password
  ]

  @type t :: %__MODULE__{
          hostname: String.t(),
          port: integer(),
          namespace: String.t(),
          database: String.t(),
          username: String.t(),
          password: String.t()
        }
end

defmodule SurrealEx.Domain.ExecutionSuccess do
  @moduledoc """
  Defines the struct for execution success.
  """

  use ExConstructor

  defstruct [
    :id,
    :result
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          result: map()
        }
end

defmodule SurrealEx.Domain.ExecutionError do
  @moduledoc """
  Defines the struct for execution error.
  """

  use ExConstructor

  defstruct [
    :id,
    :error
  ]

  defmodule SurrealError do
    use ExConstructor

    defstruct [
      :code,
      :message
    ]

    @type t :: %__MODULE__{
            code: integer(),
            message: String.t()
          }
  end

  @type t :: %__MODULE__{
          id: String.t(),
          error: SurrealError.t()
        }
end

defmodule SurrealEx.Domain.TaskOpts do
  @moduledoc """
  Defines the type for task options.
  """

  @type t :: [{:timeout, integer() | :infinity}]

  def default, do: [timeout: :infinity]
end

defmodule SurrealEx.Domain.SignInPayload do
  @moduledoc """
  Defines the struct for sign-in payload.
  """
  defstruct [
    :user,
    :pass
  ]

  @type t :: %__MODULE__{
          user: String.t(),
          pass: String.t()
        }
end

defmodule SurrealEx.Domain.QueryPayload do
  @moduledoc """
  Defines the struct for query payload.
  """
  defstruct [
    :query,
    :payload
  ]

  @type t :: %__MODULE__{
          query: String.t(),
          payload: map() | struct()
        }
end

defmodule SurrealEx.Domain.ChangePayload do
  @moduledoc """
  Defines the struct for change payload.
  """
  defstruct [
    :table,
    :payload
  ]

  @type t :: %__MODULE__{
          table: String.t(),
          payload: map() | struct()
        }
end

defmodule SurrealEx.Domain.CreatePayload do
  @moduledoc """
  Defines the struct for create payload.
  """
  defstruct [
    :table,
    :payload
  ]

  @type t :: %__MODULE__{
          table: String.t(),
          payload: map() | struct()
        }
end

defmodule SurrealEx.Domain.DeletePayload do
  @moduledoc """
  Defines the struct for delete payload.
  """
  defstruct [
    :table
  ]

  @type t :: %__MODULE__{
          table: String.t()
        }
end

defmodule SurrealEx.Domain.AuthenticatePayload do
  @moduledoc """
  Defines the struct for authenticate payload.
  """
  defstruct [
    :token
  ]

  @type t :: %__MODULE__{
          token: String.t()
        }
end

defmodule SurrealEx.Domain.UsePayload do
  @moduledoc """
  Defines the struct for use payload.
  """
  defstruct [
    :namespace,
    :database
  ]

  @type t :: %__MODULE__{
          namespace: String.t(),
          database: String.t()
        }
end

defmodule SurrealEx.Domain.LetPayload do
  @moduledoc """
  Defines the struct for let payload.
  """
  defstruct [
    :key,
    :value
  ]

  @type t :: %__MODULE__{
          key: String.t(),
          value: String.t()
        }
end

defmodule SurrealEx.Domain.LivePayload do
  @moduledoc """
  Defines the struct for live payload.
  """
  defstruct [
    :table
  ]

  @type t :: %__MODULE__{
          table: String.t()
        }
end

defmodule SurrealEx.Domain.ModifyPayload do
  @moduledoc """
  Defines the struct for modify payload.
  """
  defstruct [
    :table,
    :payload
  ]

  @type t :: %__MODULE__{
          table: String.t(),
          payload: list(map() | struct())
        }
end

defmodule SurrealEx.Domain.UpdatePayload do
  @moduledoc """
  Defines the struct for update payload.
  """
  defstruct [
    :table,
    :payload
  ]

  @type t :: %__MODULE__{
          table: String.t(),
          payload: map() | struct()
        }
end

defmodule SurrealEx.Domain.KillPayload do
  @moduledoc """
  Defines the struct for kill payload.
  """
  defstruct [
    :query
  ]

  @type t :: %__MODULE__{
          query: String.t()
        }
end

defmodule SurrealEx.Domain.SelectPayload do
  @moduledoc """
  Defines the struct for select payload.
  """
  defstruct [
    :query
  ]

  @type t :: %__MODULE__{
          query: String.t()
        }
end
