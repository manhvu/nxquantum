defmodule NxQuantum.Features.Steps.ScaleAndPerformanceSteps do
  @moduledoc false
  # credo:disable-for-this-file Credo.Check.Refactor.CyclomaticComplexity

  @behaviour NxQuantum.Features.FeatureSteps

  import ExUnit.Assertions

  alias NxQuantum.Features.StepExecutor
  alias NxQuantum.Performance
  alias NxQuantum.Runtime
  alias NxQuantum.TestSupport.Helpers
  alias NxQuantum.TestSupport.PerformanceFixtures

  @impl true
  def feature, do: "scale_and_performance.feature"

  @impl true
  def execute(step, ctx) do
    handlers = [&handle_setup/2, &handle_execution/2, &handle_assertions/2, &handle_errors/2]

    case StepExecutor.run(step, ctx, handlers) do
      {:handled, updated} -> updated
      :unhandled -> raise "unhandled step: #{step.text}"
    end
  end

  defp handle_setup(%{text: text}, ctx) do
    cond do
      text =~ ~r/^simulation strategy is / ->
        strategy = text |> Helpers.parse_quoted() |> String.to_atom()
        {:handled, Map.put(ctx, :simulation_strategy, strategy)}

      text == "qubit count exceeds the dense state-vector threshold" ->
        {:handled, ctx |> Map.put(:qubit_count, 28) |> Map.put(:dense_threshold, 20)}

      text =~ ~r/^batch size is / ->
        batch_size = text |> Helpers.parse_quoted() |> String.to_integer()
        {:handled, Map.put(ctx, :batch_size, batch_size)}

      text == "a scalar-loop reference implementation is available" ->
        {:handled, Map.put(ctx, :scalar_reference?, true)}

      text == "benchmark matrix generation is enabled" ->
        {:handled, Map.put(ctx, :benchmark_matrix_enabled?, true)}

      text == "baseline benchmark thresholds are versioned" ->
        {:handled, Map.put(ctx, :baseline_thresholds, PerformanceFixtures.baseline_thresholds())}

      text == "current benchmark run exceeds allowed regression threshold" ->
        {:handled, Map.put(ctx, :current_report, PerformanceFixtures.regressed_report())}

      true ->
        :unhandled
    end
  end

  defp handle_execution(%{text: text}, ctx) do
    cond do
      text == "I execute the circuit" ->
        result =
          Runtime.select_simulation_strategy(
            Map.get(ctx, :simulation_strategy, :auto),
            Map.get(ctx, :qubit_count, 28),
            dense_threshold: Map.get(ctx, :dense_threshold, 20)
          )

        {:handled, Map.put(ctx, :scale_result, result)}

      text == "I execute batched and scalar workflows on the same profile" ->
        assert Map.get(ctx, :scalar_reference?, false)

        batch_size = Map.get(ctx, :batch_size, 32)
        batch = PerformanceFixtures.default_batch(batch_size)
        builder = PerformanceFixtures.batch_builder()

        result =
          Performance.compare_batched_workflows(builder, batch,
            runtime_profile: :cpu_portable,
            observable: :pauli_z,
            wire: 0
          )

        {:handled, Map.put(ctx, :batch_compare, result)}

      text =~ ~r/^I run benchmark suite for batch sizes / ->
        assert Map.get(ctx, :benchmark_matrix_enabled?, false)

        batch_sizes =
          text
          |> Helpers.parse_quoted()
          |> String.split(",")
          |> Enum.map(&String.trim/1)
          |> Enum.map(&String.to_integer/1)

        result = Performance.benchmark_matrix(batch_sizes, runtime_profile: :cpu_portable)
        {:handled, Map.put(ctx, :benchmark_report, result)}

      text == "CI evaluates performance gates" ->
        result = Performance.evaluate_gates(ctx.baseline_thresholds, ctx.current_report)
        {:handled, Map.put(ctx, :gate_result, result)}

      true ->
        :unhandled
    end
  end

  defp handle_assertions(%{text: text}, ctx) do
    cond do
      text == "large-scale fallback path is selected deterministically" ->
        assert {:ok, %{selected_path: :tensor_network_fallback}} = ctx.scale_result
        {:handled, ctx}

      text == "execution report includes selected fallback strategy" ->
        assert {:ok, %{report: report}} = ctx.scale_result
        assert report.selected_strategy == :auto
        assert report.selected_path == :tensor_network_fallback
        {:handled, ctx}

      text == "error metadata includes qubit count and configured strategy" ->
        assert {:error, %{qubit_count: 28, strategy: :dense_only}} = ctx.scale_result
        {:handled, ctx}

      text == "outputs match within tolerance" ->
        assert {:ok, %{batched_values: batched_values, scalar_values: scalar_values}} = ctx.batch_compare

        batched = Nx.to_flat_list(batched_values)
        scalar = Nx.to_flat_list(scalar_values)

        batched
        |> Enum.zip(scalar)
        |> Enum.each(fn {a, b} -> assert_in_delta a, b, 1.0e-6 end)

        {:handled, ctx}

      text == "batched throughput is greater than scalar-loop throughput" ->
        assert {:ok, %{metrics: metrics}} = ctx.batch_compare
        assert metrics.batched_throughput_ops_s > metrics.scalar_throughput_ops_s
        {:handled, ctx}

      text == "report includes latency metrics per batch size" ->
        assert {:ok, %{entries: entries}} = ctx.benchmark_report
        assert Enum.all?(entries, &Map.has_key?(&1, :latency_ms))
        {:handled, ctx}

      text == "report includes throughput metrics per batch size" ->
        assert {:ok, %{entries: entries}} = ctx.benchmark_report
        assert Enum.all?(entries, &Map.has_key?(&1, :throughput_ops_s))
        {:handled, ctx}

      text == "report includes memory metrics per batch size" ->
        assert {:ok, %{entries: entries}} = ctx.benchmark_report
        assert Enum.all?(entries, &Map.has_key?(&1, :memory_mb))
        {:handled, ctx}

      text == "performance gate status is \"failed\"" ->
        assert {:ok, %{status: :failed}} = ctx.gate_result
        {:handled, ctx}

      text == "CI output includes the regressed metric and delta" ->
        assert {:ok, %{regressions: [regression | _]}} = ctx.gate_result
        assert regression.metric == :throughput_ops_s
        assert is_float(regression.delta_pct)
        {:handled, ctx}

      true ->
        :unhandled
    end
  end

  defp handle_errors(%{text: text}, ctx) do
    if text =~ ~r/^error / and text =~ ~r/ is returned$/ do
      code = text |> Helpers.parse_quoted() |> String.to_atom()
      assert {:error, %{code: ^code}} = ctx.scale_result
      {:handled, ctx}
    else
      :unhandled
    end
  end
end
