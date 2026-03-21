defmodule NxQuantum.ProviderBridge.Job do
  @moduledoc """
  Normalized provider lifecycle job envelope.
  """

  @enforce_keys [:id, :state, :provider, :target]
  defstruct [:id, :state, :provider, :target, :submitted_at, metadata: %{}]

  @type state :: :submitted | :queued | :running | :completed | :cancelled | :failed

  @type t :: %__MODULE__{
          id: String.t(),
          state: state(),
          provider: atom() | String.t() | module(),
          target: String.t(),
          submitted_at: String.t() | nil,
          metadata: map()
        }
end
