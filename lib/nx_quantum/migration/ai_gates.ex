defmodule NxQuantum.Migration.AIGates do
  @moduledoc """
  Deterministic rollout gate decisions for hybrid quantum-AI workflows.
  """

  @type decision :: :promote | :hold | :rollback

  @spec evaluate(map(), keyword()) :: {:ok, map()} | {:error, map()}
  def evaluate(evidence, opts \\ []) when is_map(evidence) and is_list(opts) do
    with :ok <- validate_inputs(evidence) do
      max_fallback_rate = Keyword.get(opts, :max_fallback_rate, 0.10)
      max_error_rate = Keyword.get(opts, :max_error_rate, 0.05)
      min_quality_delta = Keyword.get(opts, :min_quality_delta, 0.0)

      fallback_rate = Map.get(evidence, :fallback_rate, 0.0)
      error_rate = Map.get(evidence, :typed_error_rate, 0.0)
      quality_delta = Map.get(evidence, :quality_delta, 0.0)

      {decision, code} =
        cond do
          error_rate > max_error_rate -> {:rollback, :typed_error_rate_exceeded}
          fallback_rate > max_fallback_rate -> {:hold, :fallback_rate_exceeded}
          quality_delta < min_quality_delta -> {:hold, :quality_delta_below_threshold}
          true -> {:promote, :ok}
        end

      payload = %{
        schema_version: "v1",
        decision: decision,
        decision_id: decision_id(evidence, decision),
        threshold_snapshot: %{
          max_fallback_rate: max_fallback_rate,
          max_error_rate: max_error_rate,
          min_quality_delta: min_quality_delta
        },
        evidence_digest: evidence_digest(evidence),
        code: code
      }

      {:ok, payload}
    end
  end

  defp validate_inputs(evidence) do
    required = [:fallback_rate, :typed_error_rate, :quality_delta]
    missing = Enum.reject(required, &Map.has_key?(evidence, &1))
    if missing == [], do: :ok, else: {:error, %{code: :ai_rollout_invalid_input, missing: missing}}
  end

  defp decision_id(evidence, decision) do
    digest =
      :sha256
      |> :crypto.hash(:erlang.term_to_binary({evidence, decision}, [:deterministic]))
      |> Base.encode16(case: :lower)
      |> binary_part(0, 12)

    "ai_gate_#{digest}"
  end

  defp evidence_digest(evidence) do
    :sha256
    |> :crypto.hash(:erlang.term_to_binary(evidence, [:deterministic]))
    |> Base.encode16(case: :lower)
  end
end
