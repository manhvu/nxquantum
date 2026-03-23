defmodule NxQuantum.Estimator.ResultBuilder do
  @moduledoc false

  alias NxQuantum.Estimator.Result

  @spec build(Nx.Tensor.t(), [map()], keyword()) :: Result.t()
  def build(values, observable_specs, opts) do
    %Result{
      values: values,
      metadata: %{
        mode: :estimator,
        observables: observable_specs,
        runtime_profile: Keyword.get(opts, :runtime_profile, :cpu_portable),
        shots: Keyword.get(opts, :shots),
        seed: Keyword.get(opts, :seed)
      }
    }
  end
end
