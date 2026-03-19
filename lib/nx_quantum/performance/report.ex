defmodule NxQuantum.Performance.Report do
  @moduledoc false

  @enforce_keys [:profile, :entries]
  defstruct [:profile, :entries]

  @type entry :: %{
          required(:batch_size) => pos_integer(),
          required(:latency_ms) => float(),
          required(:throughput_ops_s) => float(),
          required(:memory_mb) => float()
        }

  @type t :: %__MODULE__{
          profile: atom(),
          entries: [entry()]
        }
end
