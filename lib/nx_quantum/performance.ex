defmodule NxQuantum.Performance do
  @moduledoc """
  Deterministic scale/performance helpers for benchmark evidence and CI gates.
  """

  alias NxQuantum.Performance.BatchProfiler
  alias NxQuantum.Performance.BenchmarkMatrix
  alias NxQuantum.Performance.Gates

  @type benchmark_entry :: %{
          required(:batch_size) => pos_integer(),
          required(:latency_ms) => float(),
          required(:throughput_ops_s) => float(),
          required(:memory_mb) => float()
        }

  @type benchmark_report :: %{
          required(:profile) => atom(),
          required(:entries) => [benchmark_entry()]
        }

  @type gate_regression :: %{
          required(:metric) => atom(),
          required(:batch_size) => pos_integer(),
          required(:baseline) => float(),
          required(:current) => float(),
          required(:delta_pct) => float()
        }

  @type gate_evaluation :: %{
          required(:status) => :passed | :failed,
          required(:version) => String.t(),
          required(:regressions) => [gate_regression()]
        }

  @spec compare_batched_workflows((Nx.Tensor.t() -> NxQuantum.Circuit.t()), Nx.Tensor.t(), keyword()) ::
          {:ok, map()} | {:error, map()}
  def compare_batched_workflows(circuit_builder, params_batch, opts \\ []) do
    BatchProfiler.compare(circuit_builder, params_batch, opts)
  end

  @spec benchmark_matrix([pos_integer()], keyword()) :: {:ok, benchmark_report()} | {:error, map()}
  def benchmark_matrix(batch_sizes, opts \\ []) do
    BenchmarkMatrix.run(batch_sizes, opts)
  end

  @spec evaluate_gates(map(), map()) :: {:ok, gate_evaluation()} | {:error, map()}
  def evaluate_gates(baseline, current_report) do
    Gates.evaluate(baseline, current_report)
  end
end
