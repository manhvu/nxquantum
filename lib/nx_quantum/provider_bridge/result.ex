defmodule NxQuantum.ProviderBridge.Result do
  @moduledoc """
  Normalized provider lifecycle terminal result envelope.
  """

  @enforce_keys [:job_id, :state, :provider, :target, :payload]
  defstruct [:job_id, :state, :provider, :target, :payload, metadata: %{}]

  @type t :: %__MODULE__{
          job_id: String.t(),
          state: NxQuantum.ProviderBridge.Job.state(),
          provider: atom() | String.t() | module(),
          target: String.t(),
          payload: map(),
          metadata: map()
        }
end
