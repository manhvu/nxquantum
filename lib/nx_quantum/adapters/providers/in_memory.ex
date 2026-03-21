defmodule NxQuantum.Adapters.Providers.InMemory do
  @moduledoc false

  @behaviour NxQuantum.Ports.Provider

  alias NxQuantum.ProviderBridge.CapabilityContract
  alias NxQuantum.ProviderBridge.Job
  alias NxQuantum.ProviderBridge.Result

  @impl true
  def provider_id, do: :in_memory_provider

  @impl true
  def capabilities(_target, _opts) do
    {:ok,
     %CapabilityContract{
       supports_estimator: true,
       supports_sampler: true,
       supports_batch: true,
       supports_dynamic: true,
       supports_cancel_in_running: true,
       supports_calibration_payload: true,
       target_class: :simulator
     }}
  end

  @impl true
  def submit(payload, opts \\ []) when is_map(payload) do
    job = %Job{
      id: "job_" <> Integer.to_string(:erlang.phash2(payload)),
      state: :submitted,
      provider: provider_id(),
      target: Keyword.get(opts, :target, "in_memory"),
      metadata: %{payload: payload, simulate_timeout: Keyword.get(opts, :simulate_timeout, false)}
    }

    {:ok, job}
  end

  @impl true
  def poll(%Job{metadata: %{simulate_timeout: true}}, _opts), do: {:error, :timeout}
  def poll(%Job{state: :cancelled} = job, _opts), do: {:ok, job}

  def poll(%Job{} = job, _opts) do
    {:ok, %{job | state: :completed}}
  end

  @impl true
  def cancel(%Job{} = job, _opts) do
    {:ok, %{job | state: :cancelled}}
  end

  @impl true
  def fetch_result(%Job{id: id, state: :completed, target: target, metadata: metadata}, _opts) do
    {:ok, %Result{job_id: id, state: :completed, provider: provider_id(), target: target, payload: metadata.payload}}
  end

  def fetch_result(%Job{state: state}, _opts) do
    {:error, {:invalid_state, state}}
  end
end
