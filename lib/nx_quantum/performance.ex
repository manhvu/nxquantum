defmodule NxQuantum.Performance do
  @moduledoc """
  Deterministic scale/performance helpers for benchmark evidence and CI gates.
  """

  alias NxQuantum.Performance.BatchProfiler
  alias NxQuantum.Performance.BenchmarkMatrix
  alias NxQuantum.Performance.GateResult
  alias NxQuantum.Performance.Gates
  alias NxQuantum.Performance.Report

  @spec compare_batched_workflows((Nx.Tensor.t() -> NxQuantum.Circuit.t()), Nx.Tensor.t(), keyword()) ::
          {:ok, map()} | {:error, map()}
  def compare_batched_workflows(circuit_builder, params_batch, opts \\ []) do
    BatchProfiler.compare(circuit_builder, params_batch, opts)
  end

  @spec benchmark_matrix([pos_integer()], keyword()) :: {:ok, Report.t()} | {:error, map()}
  def benchmark_matrix(batch_sizes, opts \\ []) do
    BenchmarkMatrix.run(batch_sizes, opts)
  end

  @spec evaluate_gates(map(), map()) :: {:ok, GateResult.t()} | {:error, map()}
  def evaluate_gates(baseline, current_report) do
    Gates.evaluate(baseline, current_report)
  end
end
