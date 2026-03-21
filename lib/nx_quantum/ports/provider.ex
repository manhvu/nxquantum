defmodule NxQuantum.Ports.Provider do
  @moduledoc """
  Provider bridge contract for hardware-facing job lifecycle behavior.
  """

  alias NxQuantum.ProviderBridge.CapabilityContract
  alias NxQuantum.ProviderBridge.Job
  alias NxQuantum.ProviderBridge.Result

  @type provider_id :: atom() | String.t() | module()
  @type job_state :: :submitted | :queued | :running | :completed | :cancelled | :failed
  @type payload :: map()
  @type job :: Job.t()
  @type result_payload :: Result.t()
  @type capabilities :: CapabilityContract.t()

  @callback provider_id() :: provider_id()
  @callback capabilities(String.t() | nil, keyword()) :: {:ok, capabilities()} | {:error, term()}
  @callback submit(payload(), keyword()) :: {:ok, job()} | {:error, term()}
  @callback poll(job(), keyword()) :: {:ok, job()} | {:error, term()}
  @callback cancel(job(), keyword()) :: {:ok, job()} | {:error, term()}
  @callback fetch_result(job(), keyword()) :: {:ok, result_payload()} | {:error, term()}

  @optional_callbacks capabilities: 2
end
