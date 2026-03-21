defmodule NxQuantum.Observability.PortabilityDelta do
  @moduledoc false

  @spec compute(map(), map()) :: map()
  def compute(reference, candidate) do
    ref_latency = get_in(reference, [:metadata, :latency_ms]) || 0.0
    cand_latency = get_in(candidate, [:metadata, :latency_ms]) || 0.0

    ref_expectation = get_in(reference, [:payload, :expectation]) || 0.0
    cand_expectation = get_in(candidate, [:payload, :expectation]) || 0.0

    %{
      latency_delta_ms: abs(cand_latency - ref_latency),
      expectation_delta_abs: abs(cand_expectation - ref_expectation),
      sample_kl_divergence: get_in(candidate, [:metadata, :sample_kl_divergence]) || 0.0
    }
  end
end
