defmodule NxQuantum.Features.Steps.ProviderCrossPlatformRolloutSteps do
  @moduledoc false

  @behaviour NxQuantum.Features.FeatureSteps

  @impl true
  def feature, do: "provider_cross_platform_rollout.feature"

  @impl true
  def execute(step, ctx) do
    # Draft v0.5 scaffold: captures steps for future executable implementation.
    Map.update(ctx, :v0_5_draft_steps, [{step.keyword, step.text}], &[{step.keyword, step.text} | &1])
  end
end
