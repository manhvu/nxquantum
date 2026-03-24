defmodule NxQuantum.ObservabilityAIToolCallsTest do
  use ExUnit.Case, async: true

  alias NxQuantum.Adapters.Observability.OpenTelemetry
  alias NxQuantum.Observability

  test "AI tool observability keeps request correlation and decision metadata" do
    Observability.reset(adapter: OpenTelemetry)

    _ =
      Observability.trace_lifecycle(
        :submit,
        :ai_tool_runner,
        "nxq.ai",
        :tool_execution,
        [
          enabled: true,
          adapter: OpenTelemetry,
          profile: :forensics,
          custom_metadata: %{
            "decision_id" => "ai_gate_123",
            "fallback_path" => "classical",
            "policy_version" => "v1",
            "evidence_reference" => "bench-2026-03-24"
          },
          correlation_metadata: %{request_id: "req-ai-1", correlation_id: "corr-ai-1"},
          phase: :decision_emit,
          terminal_attribution: :policy
        ],
        fn -> {:ok, %{status: :ok}} end
      )

    snapshot = Observability.snapshot(adapter: OpenTelemetry)
    last_log = List.last(snapshot.logs)

    assert last_log.custom_metadata["decision_id"] == "ai_gate_123"
    assert last_log.custom_metadata["policy_version"] == "v1"
    assert last_log.correlation_metadata["correlation.request_id"] == "req-ai-1"
  end
end
