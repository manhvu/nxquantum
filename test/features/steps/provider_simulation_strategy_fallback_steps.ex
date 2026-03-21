defmodule NxQuantum.Features.Steps.ProviderSimulationStrategyFallbackSteps do
  @moduledoc false

  @behaviour NxQuantum.Features.FeatureSteps

  @impl true
  def feature, do: "provider_simulation_strategy_fallback.feature"

  @impl true
  def execute(step, ctx) do
    # Specification scaffold: captures steps for future executable implementation.
    Map.update(ctx, :provider_spec_steps, [{step.keyword, step.text}], &[{step.keyword, step.text} | &1])
  end
end
