defmodule NxQuantum.Performance.GateResult do
  @moduledoc false

  @enforce_keys [:status, :version, :regressions]
  defstruct [:status, :version, :regressions]

  @type regression :: %{
          required(:metric) => atom(),
          required(:batch_size) => pos_integer(),
          required(:baseline) => float(),
          required(:current) => float(),
          required(:delta_pct) => float()
        }

  @type t :: %__MODULE__{
          status: :passed | :failed,
          version: String.t(),
          regressions: [regression()]
        }
end
