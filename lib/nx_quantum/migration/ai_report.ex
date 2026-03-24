defmodule NxQuantum.Migration.AIReport do
  @moduledoc """
  Machine-readable rollout report for hybrid AI promotion decisions.
  """

  @spec to_map(map(), map(), map()) :: map()
  def to_map(request, evidence, decision) when is_map(request) and is_map(evidence) and is_map(decision) do
    %{
      schema_version: "v1",
      request_id: Map.get(request, :request_id),
      correlation_id: Map.get(request, :correlation_id),
      tool_name: Map.get(request, :tool_name),
      evidence: evidence,
      decision: decision
    }
  end
end
