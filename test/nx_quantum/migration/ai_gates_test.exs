defmodule NxQuantum.Migration.AIGatesTest do
  use ExUnit.Case, async: true

  alias NxQuantum.Migration.AIGates
  alias NxQuantum.Migration.AIReport

  test "evaluate/2 emits deterministic promote decision when thresholds are met" do
    evidence = %{fallback_rate: 0.02, typed_error_rate: 0.0, quality_delta: 0.12}

    assert {:ok, promote_a} = AIGates.evaluate(evidence)
    assert {:ok, promote_b} = AIGates.evaluate(evidence)

    assert promote_a.decision == :promote
    assert promote_a.decision_id == promote_b.decision_id
    assert promote_a.code == :ok
  end

  test "evaluate/2 emits hold and rollback with typed codes" do
    assert {:ok, hold} =
             AIGates.evaluate(%{fallback_rate: 0.5, typed_error_rate: 0.01, quality_delta: 0.2},
               max_fallback_rate: 0.1
             )

    assert hold.decision == :hold
    assert hold.code == :fallback_rate_exceeded

    assert {:ok, rollback} =
             AIGates.evaluate(%{fallback_rate: 0.01, typed_error_rate: 0.2, quality_delta: 0.5},
               max_error_rate: 0.05
             )

    assert rollback.decision == :rollback
    assert rollback.code == :typed_error_rate_exceeded
  end

  test "AI report map is machine-readable and stable" do
    request = %{request_id: "req-99", correlation_id: "corr-99", tool_name: "quantum-kernel reranking"}
    evidence = %{fallback_rate: 0.02, typed_error_rate: 0.0, quality_delta: 0.12}
    {:ok, decision} = AIGates.evaluate(evidence)

    report = AIReport.to_map(request, evidence, decision)
    assert report.schema_version == "v1"
    assert report.request_id == "req-99"
    assert report.decision.decision in [:promote, :hold, :rollback]
  end
end
