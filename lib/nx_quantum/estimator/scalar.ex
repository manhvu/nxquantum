defmodule NxQuantum.Estimator.Scalar do
  @moduledoc false

  alias NxQuantum.Application.ExecuteCircuit
  alias NxQuantum.Circuit
  alias NxQuantum.Estimator.ExecutionMode
  alias NxQuantum.Estimator.Measurement
  alias NxQuantum.Estimator.RuntimeProfile
  alias NxQuantum.Estimator.Stochastic

  @spec run(Circuit.t(), keyword()) :: {:ok, Nx.Tensor.t()} | {:error, map()}
  def run(%Circuit{} = circuit, opts) do
    with {:ok, measured_circuit} <- Measurement.apply(circuit, opts),
         {:ok, profile} <- RuntimeProfile.resolve(opts) do
      tensor = ExecuteCircuit.expectation(measured_circuit, [runtime_profile: profile] ++ opts)

      if ExecutionMode.stochastic?(opts) do
        estimated =
          tensor
          |> Nx.to_number()
          |> Stochastic.apply_noise(opts)
          |> Stochastic.maybe_sample(opts)

        {:ok, Nx.tensor(estimated, type: {:f, 32})}
      else
        {:ok, Nx.as_type(tensor, {:f, 32})}
      end
    end
  end
end
