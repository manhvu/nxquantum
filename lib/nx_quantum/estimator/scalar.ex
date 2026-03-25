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
         {:ok, selection} <- RuntimeProfile.resolve_with_context(opts, kind: :scalar, qubits: measured_circuit.qubits) do
      simulator_opts = [runtime_profile: selection.profile] ++ opts
      tensor = ExecuteCircuit.expectation(measured_circuit, simulator_opts)

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
