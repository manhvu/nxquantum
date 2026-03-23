defmodule NxQuantum.Features.Steps.MigrationAssuranceWorkflowsSteps do
  @moduledoc false

  @behaviour NxQuantum.Features.FeatureSteps

  alias NxQuantum.Features.Steps.RoadmapContractSteps

  @decisions ["promote", "hold", "rollback"]

  @scenario_configs %{
    "Manifest contracts are canonical and reproducible" => %{
      given: "migration assurance workflows require canonical manifest generation",
      when: "migration manifests are produced for equivalent workflow inputs",
      expectations: [
        "manifest fingerprints stay stable for identical workflow provider target runtime profile and seed inputs",
        "manifest payloads include workflow provider target runtime_profile seed and dataset_hash fields",
        "manifest serialization remains deterministic across repeated runs"
      ]
    },
    "Comparison and reporting contracts stay machine-readable and linked" => %{
      given: "migration comparison and reporting outputs must be CI-ingestable",
      when: "migration reports are exported",
      expectations: [
        "comparison outputs include tolerance_budget_id observed_delta allowed_delta and pass_fail fields per metric",
        "migration report exports include schema_version manifest_fingerprint comparison_summary and gate_decision fields",
        "migration evidence links provider lifecycle correlation_id and observability trace_id without contract drift"
      ]
    }
  }

  @impl true
  def feature, do: "migration_assurance_workflows.feature"

  @impl true
  def execute(step, ctx) do
    config = scenario_config(ctx)
    expectations = Map.fetch!(config, :expectations)

    ctx
    |> RoadmapContractSteps.bootstrap(expectations)
    |> then(&RoadmapContractSteps.execute(step, &1, config))
  end

  defp scenario_config(%{scenario: scenario}) do
    case Regex.run(
           ~r/^Gate decision (.+) is a typed first-class contract$/,
           scenario,
           capture: :all_but_first
         ) do
      [decision] ->
        if decision in @decisions do
          decision_config(decision)
        else
          raise "unsupported decision in scenario: #{decision}"
        end

      _ ->
        Map.fetch!(@scenario_configs, scenario)
    end
  end

  defp decision_config(decision) do
    %{
      given: "migration gate decision #{decision} is part of shadow-mode promotion workflows",
      when: "migration comparisons are evaluated for #{decision} outcomes",
      expectations: [
        "gate decisions emit deterministic #{decision} outcomes with typed reason codes",
        "decision payloads include tolerance_budget_id comparison_summary and blocking_metric identifiers",
        "CI promotion checks treat #{decision} as a first-class typed result"
      ]
    }
  end
end
