defmodule NxQuantum.Features.Steps.HighValuePerformanceMatrixSteps do
  @moduledoc false

  @behaviour NxQuantum.Features.FeatureSteps

  alias NxQuantum.Features.Steps.RoadmapContractSteps

  @scenario_ids [
    "state_reuse_8q_xy",
    "batch_obs_8q",
    "sampled_counts_sparse_terms",
    "shot_sweep_param_grid_v1"
  ]

  @lanes ["fixture", "live_smoke", "live"]

  @scenario_configs %{
    "Shot-heavy parameter sweep datasets are fixed and auditable" => %{
      given: "shot-heavy parameter sweep benchmarking is required for provider-relevant workloads",
      when: "shot sweep dataset contracts are finalized",
      expectations: [
        "shot sweep datasets include fixed shot tiers 256 1024 and 4096 with pinned parameter grid metadata",
        "shot sweep manifests include grid_id parameter_count and sweep_seed fields",
        "report outputs include latency throughput and fallback-rate measurements for each shot tier"
      ]
    }
  }

  @impl true
  def feature, do: "high_value_performance_matrix.feature"

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
           ~r/^High-value simulation scenario (.+) has pinned evidence contracts$/,
           scenario,
           capture: :all_but_first
         ) do
      [scenario_id] ->
        if scenario_id in @scenario_ids do
          simulation_config(scenario_id)
        else
          raise "unsupported simulation scenario: #{scenario_id}"
        end

      _ ->
        lane_or_static_config(scenario)
    end
  end

  defp lane_or_static_config(scenario) do
    case Regex.run(
           ~r/^Provider lifecycle latency lane (.+) is benchmarked end-to-end$/,
           scenario,
           capture: :all_but_first
         ) do
      [lane] ->
        if lane in @lanes do
          lane_config(lane)
        else
          raise "unsupported latency lane: #{lane}"
        end

      _ ->
        Map.fetch!(@scenario_configs, scenario)
    end
  end

  defp simulation_config(scenario_id) do
    %{
      given: "performance scenario #{scenario_id} is prioritized for Q/ML engineering decisions",
      when: "benchmark harness coverage for #{scenario_id} is delivered",
      expectations: [
        "deterministic harness includes scenario #{scenario_id} with version-pinned runtime metadata",
        "performance dataset manifests include dataset_id schema_version seed and sha256 fields",
        "CI regression guards enforce scenario-specific thresholds for #{scenario_id}"
      ]
    }
  end

  defp lane_config(lane) do
    %{
      given: "provider lifecycle latency benchmarking supports #{lane} lane execution",
      when: "provider lifecycle benchmark scripts for #{lane} are implemented",
      expectations: [
        "provider lifecycle latency scripts cover submit poll cancel and fetch_result for #{lane} lanes",
        "lane reports include transport mode provider target and credential policy metadata",
        "benchmark reports publish version-pinned Qiskit and Cirq comparisons with explicit caveat labels"
      ]
    }
  end
end
