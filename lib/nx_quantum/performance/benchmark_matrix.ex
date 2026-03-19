defmodule NxQuantum.Performance.BenchmarkMatrix do
  @moduledoc false

  alias NxQuantum.Performance.Model
  alias NxQuantum.Performance.Report

  @spec run([pos_integer()], keyword()) :: {:ok, Report.t()} | {:error, map()}
  def run(batch_sizes, opts \\ []) when is_list(batch_sizes) do
    invalid_batch_sizes = Enum.reject(batch_sizes, &(is_integer(&1) and &1 > 0))

    if invalid_batch_sizes == [] do
      profile = Keyword.get(opts, :runtime_profile, :cpu_portable)
      entries = Enum.map(batch_sizes, &metric_entry(&1, profile))
      {:ok, %Report{profile: profile, entries: entries}}
    else
      {:error, %{code: :invalid_benchmark_batch_sizes, invalid_batch_sizes: invalid_batch_sizes}}
    end
  end

  defp metric_entry(batch_size, profile) do
    latency_ms = Model.benchmark_latency_ms(batch_size, profile)

    %{
      batch_size: batch_size,
      latency_ms: latency_ms,
      throughput_ops_s: Model.throughput_ops_s(batch_size, latency_ms),
      memory_mb: Model.memory_mb(batch_size, :benchmark)
    }
  end
end
