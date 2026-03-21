defmodule NxQuantum.ObservabilityTest do
  use ExUnit.Case, async: true

  alias NxQuantum.Adapters.Observability.OpenTelemetry
  alias NxQuantum.Observability

  test "fingerprint is deterministic for equivalent canonicalized inputs" do
    input = %{workflow: :sampler, shots: 1024, circuit: ["h", "cnot"], seed: 7}

    assert Observability.fingerprint(input) == Observability.fingerprint(input)
  end

  test "portability delta exposes stable schema" do
    delta =
      Observability.portability_delta(
        %{payload: %{expectation: 0.9}, metadata: %{latency_ms: 10.0}},
        %{payload: %{expectation: 0.85}, metadata: %{latency_ms: 12.0, sample_kl_divergence: 0.02}}
      )

    assert Map.has_key?(delta, :latency_delta_ms)
    assert Map.has_key?(delta, :expectation_delta_abs)
    assert Map.has_key?(delta, :sample_kl_divergence)
  end

  test "open telemetry adapter stores spans, metrics, and logs" do
    Observability.reset(adapter: OpenTelemetry)

    _ =
      Observability.trace_lifecycle(
        :submit,
        :ibm_runtime,
        "ibm_backend",
        :sampler,
        [enabled: true, adapter: OpenTelemetry, profile: :high_level],
        fn ->
          {:ok, %{id: "job_1"}}
        end
      )

    snapshot = Observability.snapshot(adapter: OpenTelemetry)

    assert match?([_, _ | _], snapshot.spans)
    assert match?([_, _ | _], snapshot.metrics)
    assert match?([_ | _], snapshot.logs)
  end
end
