defmodule NxQuantum.Performance.Metrics do
  @moduledoc false

  @enforce_keys [
    :batch_size,
    :scalar_latency_ms,
    :batched_latency_ms,
    :scalar_throughput_ops_s,
    :batched_throughput_ops_s,
    :estimated_memory_mb
  ]
  defstruct [
    :batch_size,
    :scalar_latency_ms,
    :batched_latency_ms,
    :scalar_throughput_ops_s,
    :batched_throughput_ops_s,
    :estimated_memory_mb
  ]

  @type t :: %__MODULE__{
          batch_size: pos_integer(),
          scalar_latency_ms: float(),
          batched_latency_ms: float(),
          scalar_throughput_ops_s: float(),
          batched_throughput_ops_s: float(),
          estimated_memory_mb: float()
        }
end
