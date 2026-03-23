defmodule NxQuantum.Estimator.Batch.Strategy do
  @moduledoc false

  alias NxQuantum.Circuit
  alias NxQuantum.Estimator.Result

  @callback run(Circuit.t(), [map()], keyword()) :: {:ok, Result.t()} | {:error, map()}
end
