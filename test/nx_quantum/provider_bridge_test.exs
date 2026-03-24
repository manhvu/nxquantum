defmodule NxQuantum.ProviderBridgeTest do
  use ExUnit.Case, async: true

  alias NxQuantum.Adapters.Providers.InMemory
  alias NxQuantum.ProviderBridge

  defmodule BrokenProvider do
    @moduledoc false
    @behaviour NxQuantum.Ports.Provider

    @impl true
    def provider_id, do: :broken_provider

    @impl true
    def submit(_payload, _opts), do: :not_a_tuple

    @impl true
    def poll(_job, _opts), do: raise("transport down")

    @impl true
    def cancel(_job, _opts), do: {:ok, %{state: :cancelled}}

    @impl true
    def fetch_result(_job, _opts), do: {:error, {:invalid_state, :submitted}}
  end

  test "run_lifecycle/3 returns deterministic submitted, polled and result payloads" do
    payload = %{circuit_id: "c1", shots: 128}

    assert {:ok, %{submitted: submitted, polled: polled, result: result}} =
             ProviderBridge.run_lifecycle(InMemory, payload)

    assert submitted.state == :submitted
    assert polled.state == :completed
    assert result.state == :completed
    assert result.payload == payload
    assert submitted.schema_version == :v1
    assert polled.schema_version == :v1
    assert result.schema_version == :v1
    assert is_binary(submitted.request_id)
    assert is_binary(polled.request_id)
    assert is_binary(result.request_id)
    assert is_binary(submitted.correlation_id)
    assert is_binary(submitted.idempotency_key)
    assert is_binary(result.correlation_id)
    assert is_binary(result.idempotency_key)
  end

  test "poll_job/3 maps timeout to provider_transport_error" do
    assert {:ok, submitted} = InMemory.submit(%{circuit_id: "c1"}, simulate_timeout: true)

    assert {:error, %{code: :provider_transport_error, operation: :poll, provider: :in_memory_provider, reason: :timeout}} =
             ProviderBridge.poll_job(InMemory, submitted, simulate_timeout: true)
  end

  test "submit_job/3 accepts explicit correlation and idempotency contract fields" do
    assert {:ok, submitted} =
             ProviderBridge.submit_job(InMemory, %{circuit_id: "c2"},
               request_id: "req_external_123",
               correlation_id: "corr_external_123",
               idempotency_key: "idem_external_123"
             )

    assert submitted.request_id == "req_external_123"
    assert submitted.correlation_id == "corr_external_123"
    assert submitted.idempotency_key == "idem_external_123"
    assert submitted.metadata.contract_schema_version == :v1
  end

  test "submit_job/3 maps invalid provider response shape" do
    assert {:error,
            %{code: :provider_invalid_response, operation: :submit, provider: :broken_provider, response: :not_a_tuple}} =
             ProviderBridge.submit_job(BrokenProvider, %{circuit_id: "c1"})
  end

  test "poll_job/3 maps raised exception to provider_transport_error" do
    assert {:error, %{code: :provider_transport_error, operation: :poll, provider: :broken_provider}} =
             ProviderBridge.poll_job(BrokenProvider, %{id: "job_1"})
  end
end
