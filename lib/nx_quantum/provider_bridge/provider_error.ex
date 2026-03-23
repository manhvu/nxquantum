defmodule NxQuantum.ProviderBridge.ProviderError do
  @moduledoc """
  Typed provider error envelope.
  """

  @enforce_keys [:code, :operation, :provider]
  defstruct [
    :code,
    :operation,
    :provider,
    :reason,
    :state,
    :response,
    :capability,
    :schema_version,
    :correlation_id,
    :idempotency_key,
    metadata: %{}
  ]

  @type code ::
          :provider_transport_error
          | :provider_auth_error
          | :provider_invalid_state
          | :provider_invalid_response
          | :provider_capability_mismatch
          | :provider_execution_error
          | :provider_rate_limited

  @type t :: %__MODULE__{
          code: code(),
          operation: atom(),
          provider: atom() | String.t() | module(),
          reason: term() | nil,
          state: atom() | nil,
          response: term() | nil,
          capability: atom() | nil,
          schema_version: atom() | nil,
          correlation_id: String.t() | nil,
          idempotency_key: String.t() | nil,
          metadata: map()
        }
end
