defmodule NxQuantum.TestSupport.PerformanceFixtures do
  @moduledoc false

  alias NxQuantum.Circuit
  alias NxQuantum.Gates

  def baseline_thresholds do
    %{
      version: "2026.03",
      max_regression_pct: 10.0,
      throughput_by_batch: %{1 => 1333.333, 8 => 1333.333, 32 => 3030.303, 128 => 3030.303}
    }
  end

  def regressed_report do
    %{
      profile: :cpu_portable,
      entries: [
        %{batch_size: 1, latency_ms: 0.75, throughput_ops_s: 1333.333, memory_mb: 48.15},
        %{batch_size: 8, latency_ms: 6.0, throughput_ops_s: 1333.333, memory_mb: 49.2},
        %{batch_size: 32, latency_ms: 20.0, throughput_ops_s: 1600.0, memory_mb: 52.8},
        %{batch_size: 128, latency_ms: 42.24, throughput_ops_s: 3030.303, memory_mb: 67.2}
      ]
    }
  end

  def batch_builder do
    fn theta ->
      [qubits: 1]
      |> Circuit.new()
      |> Gates.ry(0, theta: theta)
    end
  end

  def default_batch(batch_size) do
    {batch_size} |> Nx.iota(type: {:f, 32}) |> Nx.divide(10.0)
  end
end
