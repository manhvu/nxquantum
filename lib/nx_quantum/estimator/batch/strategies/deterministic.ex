defmodule NxQuantum.Estimator.Batch.Strategies.Deterministic do
  @moduledoc false

  @behaviour NxQuantum.Estimator.Batch.Strategy

  alias NxQuantum.Application.ExecuteCircuit
  alias NxQuantum.Circuit
  alias NxQuantum.Estimator.ResultBuilder
  alias NxQuantum.Estimator.RuntimeProfile

  @impl true
  @spec run(Circuit.t(), [map()], keyword()) :: {:ok, NxQuantum.Estimator.Result.t()} | {:error, map()}
  def run(_circuit, [], opts) do
    {:ok, ResultBuilder.build(Nx.tensor([], type: {:f, 32}), [], opts)}
  end

  def run(circuit, observable_specs, opts) do
    measured_circuit = %{circuit | measurement: hd(observable_specs)}

    with {:ok, profile} <- RuntimeProfile.resolve(opts) do
      values =
        measured_circuit
        |> ExecuteCircuit.expectations(observable_specs, [runtime_profile: profile] ++ opts)
        |> Nx.as_type({:f, 32})

      {:ok, ResultBuilder.build(values, observable_specs, opts)}
    end
  end
end
