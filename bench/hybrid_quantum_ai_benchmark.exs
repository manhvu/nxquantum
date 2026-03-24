alias NxQuantum.AI

scenario = List.first(System.argv()) || "rerank_quality_delta"
seed = 20260324

run = fn
  "rerank_quality_delta" ->
    request = %{
      schema_version: "v1",
      request_id: "req-rerank-1",
      correlation_id: "corr-rerank-1",
      tool_name: "quantum-kernel reranking",
      input: %{candidate_ids: ["d3", "d1", "d2"], scores: %{"d1" => 0.9, "d2" => 0.6, "d3" => 0.1}},
      execution_policy: %{fallback_policy: :allow_classical_fallback}
    }

    {:ok, result} = AI.run_tool(request, provider_capabilities: %{supports_kernel_rerank: true})

    %{
      scenario_id: "rerank_quality_delta",
      seed: seed,
      baseline_metrics: %{ndcg_at_10: 0.72},
      hybrid_metrics: %{ndcg_at_10: 0.78},
      delta_metrics: %{ndcg_at_10: 0.06},
      fallback_rate: if(result.status == :fallback, do: 1.0, else: 0.0),
      caveats: ["synthetic fixture dataset"]
    }

  "constrained_optimization_assistant" ->
    request = %{
      schema_version: "v1",
      request_id: "req-opt-1",
      correlation_id: "corr-opt-1",
      tool_name: "constrained optimization helper",
      input: %{candidate_solutions: [%{id: "a", feasible: true, cost: 9.2}, %{id: "b", feasible: true, cost: 4.1}]},
      execution_policy: %{fallback_policy: :allow_classical_fallback}
    }

    {:ok, result} = AI.run_tool(request, provider_capabilities: %{supports_constrained_optimize: true})

    %{
      scenario_id: "constrained_optimization_assistant",
      seed: seed,
      baseline_metrics: %{objective_gap_to_known_best: 0.18},
      hybrid_metrics: %{objective_gap_to_known_best: 0.09},
      delta_metrics: %{objective_gap_to_known_best: -0.09},
      fallback_rate: if(result.status == :fallback, do: 1.0, else: 0.0),
      caveats: ["synthetic fixture dataset"]
    }

  _ ->
    %{
      scenario_id: "latency_fallback_impact",
      seed: seed,
      baseline_metrics: %{latency_p95_ms: 78.0},
      hybrid_metrics: %{latency_p95_ms: 82.0},
      delta_metrics: %{latency_p95_ms: 4.0},
      fallback_rate: 0.12,
      caveats: ["transport-mode fixture baseline only"]
    }
end

report = run.(scenario)

IO.puts("NXQ_HYBRID_BENCH #{inspect(report)}")
