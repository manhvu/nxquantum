defmodule NxQuantum.Performance.Model do
  @moduledoc false

  @spec profile_factor(atom()) :: float()
  def profile_factor(:cpu_portable), do: 1.0
  def profile_factor(:cpu_compiled), do: 0.8
  def profile_factor(:nvidia_gpu_compiled), do: 0.6
  def profile_factor(:torch_interop_runtime), do: 0.9
  def profile_factor(_unknown), do: 1.0

  @spec scalar_latency_ms(pos_integer(), atom()) :: float()
  def scalar_latency_ms(batch_size, profile) do
    Float.round(batch_size * 0.8 * profile_factor(profile), 3)
  end

  @spec batched_latency_ms(pos_integer(), atom()) :: float()
  def batched_latency_ms(batch_size, profile) do
    if batch_size >= 32 do
      Float.round(batch_size * 0.35 * profile_factor(profile), 3)
    else
      Float.round(batch_size * 0.9 * profile_factor(profile), 3)
    end
  end

  @spec benchmark_latency_ms(pos_integer(), atom()) :: float()
  def benchmark_latency_ms(batch_size, profile) do
    if batch_size >= 32 do
      Float.round(batch_size * 0.33 * profile_factor(profile), 3)
    else
      Float.round(batch_size * 0.75 * profile_factor(profile), 3)
    end
  end

  @spec throughput_ops_s(pos_integer(), float()) :: float()
  def throughput_ops_s(batch_size, latency_ms) do
    Float.round(batch_size / (latency_ms / 1000.0), 3)
  end

  @spec memory_mb(pos_integer(), :compare | :benchmark) :: float()
  def memory_mb(batch_size, :compare), do: Float.round(40.0 + batch_size * 0.12, 3)
  def memory_mb(batch_size, :benchmark), do: Float.round(48.0 + batch_size * 0.15, 3)
end
