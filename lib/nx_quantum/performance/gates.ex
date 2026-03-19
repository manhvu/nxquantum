defmodule NxQuantum.Performance.Gates do
  @moduledoc false

  alias NxQuantum.Performance.GateResult

  @spec evaluate(map(), map()) :: {:ok, GateResult.t()} | {:error, map()}
  def evaluate(%{version: version, max_regression_pct: max_regression_pct} = baseline, current_report)
      when is_binary(version) and is_number(max_regression_pct) do
    baseline_by_batch = Map.get(baseline, :throughput_by_batch, %{})
    current_by_batch = throughput_by_batch(current_report)

    with :ok <- validate_baseline_values(baseline_by_batch) do
      regressions =
        Enum.reduce_while(baseline_by_batch, [], fn {batch_size, baseline_value}, acc ->
          case Map.fetch(current_by_batch, batch_size) do
            :error ->
              {:halt, {:error, %{code: :missing_benchmark_metric, batch_size: batch_size}}}

            {:ok, current_value} ->
              floor_value = baseline_value * (1.0 - max_regression_pct / 100.0)

              if current_value < floor_value do
                delta_pct = Float.round((current_value - baseline_value) / baseline_value * 100.0, 3)

                {:cont,
                 [
                   %{
                     metric: :throughput_ops_s,
                     batch_size: batch_size,
                     baseline: baseline_value,
                     current: current_value,
                     delta_pct: delta_pct
                   }
                   | acc
                 ]}
              else
                {:cont, acc}
              end
          end
        end)

      case regressions do
        {:error, _} = error ->
          error

        regression_list ->
          ordered = Enum.reverse(regression_list)
          status = if ordered == [], do: :passed, else: :failed
          {:ok, %GateResult{status: status, version: version, regressions: ordered}}
      end
    end
  end

  def evaluate(_baseline, _current_report) do
    {:error, %{code: :invalid_performance_gate_input}}
  end

  defp validate_baseline_values(baseline_by_batch) do
    case Enum.find(baseline_by_batch, fn {_batch_size, value} -> not is_number(value) or value <= 0 end) do
      nil -> :ok
      {batch_size, value} -> {:error, %{code: :invalid_baseline_threshold, batch_size: batch_size, value: value}}
    end
  end

  defp throughput_by_batch(%{entries: entries}) when is_list(entries) do
    Map.new(entries, fn entry -> {entry.batch_size, entry.throughput_ops_s} end)
  end

  defp throughput_by_batch(_invalid), do: %{}
end
