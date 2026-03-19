defmodule NxQuantum.PerformanceTest do
  use ExUnit.Case, async: true

  alias NxQuantum.Circuit
  alias NxQuantum.Gates
  alias NxQuantum.Performance

  test "compare_batched_workflows/3 preserves scalar equivalence and improves throughput for batch >= 32" do
    builder = fn theta ->
      [qubits: 1]
      |> Circuit.new()
      |> Gates.ry(0, theta: theta)
    end

    batch = {32} |> Nx.iota(type: {:f, 32}) |> Nx.divide(10.0)

    assert {:ok, %{batched_values: batched_values, scalar_values: scalar_values, metrics: metrics}} =
             Performance.compare_batched_workflows(builder, batch,
               runtime_profile: :cpu_portable,
               observable: :pauli_z,
               wire: 0
             )

    assert Nx.to_flat_list(batched_values) == Nx.to_flat_list(scalar_values)
    assert metrics.batched_throughput_ops_s > metrics.scalar_throughput_ops_s
  end

  test "benchmark_matrix/2 returns latency throughput and memory metrics for each batch size" do
    assert {:ok, %{entries: entries}} =
             Performance.benchmark_matrix([1, 8, 32, 128], runtime_profile: :cpu_portable)

    assert Enum.map(entries, & &1.batch_size) == [1, 8, 32, 128]
    assert Enum.all?(entries, &Map.has_key?(&1, :latency_ms))
    assert Enum.all?(entries, &Map.has_key?(&1, :throughput_ops_s))
    assert Enum.all?(entries, &Map.has_key?(&1, :memory_mb))
  end

  test "benchmark_matrix/2 returns typed invalid batch size diagnostics" do
    assert {:error, %{code: :invalid_benchmark_batch_sizes, invalid_batch_sizes: [0, -1, "x"]}} =
             Performance.benchmark_matrix([1, 0, -1, "x"], runtime_profile: :cpu_portable)
  end

  test "evaluate_gates/2 marks throughput regression beyond threshold as failed" do
    baseline = %{
      version: "2026.03",
      max_regression_pct: 10.0,
      throughput_by_batch: %{1 => 1333.333, 8 => 1333.333, 32 => 3030.303, 128 => 3030.303}
    }

    current_report = %{
      entries: [
        %{batch_size: 1, throughput_ops_s: 1333.333},
        %{batch_size: 8, throughput_ops_s: 1333.333},
        %{batch_size: 32, throughput_ops_s: 1600.0},
        %{batch_size: 128, throughput_ops_s: 3030.303}
      ]
    }

    assert {:ok, %{status: :failed, regressions: [regression | _]}} =
             Performance.evaluate_gates(baseline, current_report)

    assert regression.metric == :throughput_ops_s
    assert regression.batch_size == 32
    assert regression.delta_pct < 0.0
  end

  test "evaluate_gates/2 returns typed error when benchmark metric is missing" do
    baseline = %{
      version: "2026.03",
      max_regression_pct: 10.0,
      throughput_by_batch: %{1 => 1333.333, 8 => 1333.333}
    }

    current_report = %{entries: [%{batch_size: 1, throughput_ops_s: 1333.333}]}

    assert {:error, %{code: :missing_benchmark_metric, batch_size: 8}} =
             Performance.evaluate_gates(baseline, current_report)
  end
end
