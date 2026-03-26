defmodule NxQuantum.Adapters.Providers.GoogleQuantumAI do
  @moduledoc """
  Deterministic Google Quantum AI provider adapter behind `NxQuantum.Ports.Provider`.
  """

  @behaviour NxQuantum.Ports.Provider

  alias NxQuantum.Adapters.Providers.Common.LifecycleSupport
  alias NxQuantum.Adapters.Providers.Common.LiveTransport
  alias NxQuantum.Adapters.Providers.Common.StateMapper
  alias NxQuantum.Adapters.Providers.Common.TransportSupport
  alias NxQuantum.ProviderBridge.Job
  alias NxQuantum.Providers.Config

  @submit_states %{"SUBMITTED" => :submitted, "QUEUED" => :queued, "RUNNING" => :running}
  @poll_states Map.merge(@submit_states, %{"SUCCEEDED" => :completed, "CANCELLED" => :cancelled, "FAILED" => :failed})
  @transport_required_config_keys [:auth_token, :project_id, :location, :processor_id]

  @capabilities %NxQuantum.ProviderBridge.CapabilityContract{
    supports_estimator: true,
    supports_sampler: true,
    supports_batch: true,
    supports_dynamic: false,
    supports_cancel_in_running: true,
    supports_calibration_payload: true,
    target_class: :gate_model
  }

  @impl true
  def provider_id, do: :google_quantum_ai

  @impl true
  def capabilities(_target, _opts), do: {:ok, @capabilities}

  @spec transport_readiness(keyword()) :: {:ok, map()}
  def transport_readiness(opts \\ []),
    do: {:ok, TransportSupport.readiness(provider_id(), opts, @transport_required_config_keys, :submit)}

  @impl true
  def submit(payload, opts \\ []) when is_map(payload) do
    transport = TransportSupport.readiness(provider_id(), opts, @transport_required_config_keys, :submit)

    with :ok <- LifecycleSupport.maybe_force_error(:submit, opts),
         :ok <- TransportSupport.require_live_ready(transport, :submit),
         {:ok, _config} <- Config.fetch_required(provider_id(), opts, @transport_required_config_keys, :submit),
         {:ok, live_response} <- live_response(:submit, payload, transport, opts),
         {:ok, raw_state} <- raw_state(:submit, opts, live_response),
         {:ok, state, metadata} <- StateMapper.map(:submit, provider_id(), @submit_states, raw_state, target(opts)) do
      LifecycleSupport.maybe_notify_submit(provider_id(), opts)

      {:ok,
       %Job{
         id: job_id(payload, opts),
         state: state,
         provider: provider_id(),
         target: target(opts),
         submitted_at: LifecycleSupport.submitted_at(opts),
         metadata:
           Map.merge(metadata, %{
             workflow: Map.get(payload, :workflow),
             shots: Map.get(payload, :shots),
             provider_payload_version: "google_quantum_ai.v1",
             transport: transport
           })
       }}
    end
  end

  @impl true
  def poll(%Job{} = job, opts \\ []) do
    transport = TransportSupport.readiness(provider_id(), opts, [], :poll)

    with :ok <- LifecycleSupport.maybe_force_error(:poll, opts),
         :ok <- TransportSupport.require_live_ready(transport, :poll),
         {:ok, live_response} <- live_response(:poll, Map.from_struct(job), transport, opts),
         {:ok, raw_state} <- raw_state(:poll, opts, live_response),
         {:ok, state, metadata} <-
           StateMapper.map(:poll, provider_id(), @poll_states, raw_state, job.target, %{job_id: job.id}) do
      {:ok, %{job | state: state, metadata: Map.merge(job.metadata || %{}, Map.put(metadata, :transport, transport))}}
    end
  end

  @impl true
  def cancel(%Job{} = job, opts \\ []) do
    transport = TransportSupport.readiness(provider_id(), opts, [], :cancel)

    with :ok <- LifecycleSupport.maybe_force_error(:cancel, opts),
         :ok <- TransportSupport.require_live_ready(transport, :cancel),
         {:ok, live_response} <- live_response(:cancel, Map.from_struct(job), transport, opts),
         {:ok, raw_state} <- raw_state(:cancel, opts, live_response),
         {:ok, state, metadata} <-
           StateMapper.map(:cancel, provider_id(), %{"CANCELLED" => :cancelled}, raw_state, job.target, %{
             job_id: job.id
           }) do
      {:ok, %{job | state: state, metadata: Map.merge(job.metadata || %{}, Map.put(metadata, :transport, transport))}}
    end
  end

  @impl true
  def fetch_result(%Job{state: state} = job, opts \\ []) do
    transport = TransportSupport.readiness(provider_id(), opts, [], :fetch_result)

    with :ok <- LifecycleSupport.maybe_force_error(:fetch_result, opts),
         :ok <- TransportSupport.require_live_ready(transport, :fetch_result),
         :ok <- LifecycleSupport.validate_terminal_state(state) do
      payload = result_payload(job, transport, opts)
      result = LifecycleSupport.result(job, provider_id(), "google_quantum_ai.v1", payload)

      {:ok, %{result | metadata: Map.put(result.metadata, :transport, transport)}}
    end
  end

  defp default_raw_state(:submit), do: "SUBMITTED"
  defp default_raw_state(:poll), do: "SUCCEEDED"
  defp default_raw_state(:cancel), do: "CANCELLED"

  defp default_payload(%Job{} = job), do: LifecycleSupport.default_sampler_payload(job)

  defp job_id(payload, opts) do
    LifecycleSupport.deterministic_job_id("google_job", payload, target(opts), opts)
  end

  defp target(opts) do
    LifecycleSupport.target(opts, :processor_id, "unknown_target")
  end

  defp live_response(_operation, _payload, %{mode: mode}, _opts) when mode in [:fixture, :live_smoke], do: {:ok, %{}}

  defp live_response(operation, payload, _transport, opts),
    do: LiveTransport.lifecycle(provider_id(), operation, payload, opts)

  defp raw_state(_operation, _opts, %{raw_state: raw_state}) when is_binary(raw_state), do: {:ok, raw_state}
  defp raw_state(operation, opts, _response), do: LifecycleSupport.raw_state(operation, opts, &default_raw_state/1)

  defp result_payload(job, %{mode: :fixture}, opts), do: Keyword.get(opts, :fixture_payload, default_payload(job))

  defp result_payload(job, _transport, opts) do
    case LiveTransport.lifecycle(provider_id(), :fetch_result, Map.from_struct(job), opts) do
      {:ok, %{payload: %{} = payload}} -> payload
      _ -> default_payload(job)
    end
  end
end
