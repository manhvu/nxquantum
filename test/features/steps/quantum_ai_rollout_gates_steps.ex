defmodule NxQuantum.Features.Steps.QuantumAiRolloutGatesSteps do
  @moduledoc false

  @behaviour NxQuantum.Features.FeatureSteps

  alias NxQuantum.Features.Steps.RoadmapContractSteps

  @decisions ["promote", "hold", "rollback"]
  @operations ["request_ingest", "policy_evaluation", "decision_emit"]

  @scenario_configs %{
    "Gate inputs enforce schema compatibility before evaluation" => %{
      given: "rollout gates consume migration assurance and hybrid benchmark artifacts",
      when: "rollout gate input validation runs",
      expectations: [
        "gate inputs consume migration assurance artifacts and hybrid benchmark outputs without schema drift",
        "schema mismatches fail fast with typed diagnostics and remediation hints",
        "acceptance and unit tests cover threshold policy determinism and rollback trigger behavior"
      ]
    }
  }

  @impl true
  def feature, do: "quantum_ai_rollout_gates.feature"

  @impl true
  def execute(step, ctx) do
    config = scenario_config(ctx)
    expectations = Map.fetch!(config, :expectations)

    ctx
    |> RoadmapContractSteps.bootstrap(expectations)
    |> then(&RoadmapContractSteps.execute(step, &1, config))
  end

  defp scenario_config(%{scenario: scenario}) do
    case Regex.run(~r/^Rollout decision (.+) is deterministic and typed$/, scenario, capture: :all_but_first) do
      [decision] ->
        if decision in @decisions do
          decision_config(decision)
        else
          raise "unsupported rollout decision in scenario: #{decision}"
        end

      _ ->
        operation_or_static_config(scenario)
    end
  end

  defp operation_or_static_config(scenario) do
    case Regex.run(
           ~r/^AI tool observability correlation covers (.+)$/,
           scenario,
           capture: :all_but_first
         ) do
      [operation] ->
        if operation in @operations do
          operation_config(operation)
        else
          raise "unsupported rollout observability operation in scenario: #{operation}"
        end

      _ ->
        Map.fetch!(@scenario_configs, scenario)
    end
  end

  defp decision_config(decision) do
    %{
      given: "rollout decision #{decision} is part of production promotion policy",
      when: "rollout policy evaluation returns #{decision}",
      expectations: [
        "promotion decisions emit deterministic #{decision} outcomes with typed reason codes",
        "decision payload includes decision_id threshold_snapshot and evidence_digest fields",
        "rollout playbooks define operator actions for #{decision} outcomes"
      ]
    }
  end

  defp operation_config(operation) do
    %{
      given: "AI tool rollout observability tracks #{operation} lifecycle events",
      when: "observability enrichment for #{operation} is delivered",
      expectations: [
        "observability contracts propagate request correlation decision_id and fallback-path metadata for AI tool calls",
        "#{operation} events include policy_version gate_threshold_profile and evidence_reference fields",
        "troubleshooting queries can reconstruct #{operation} decision context deterministically"
      ]
    }
  end
end
