defmodule NxQuantum.Adapters.Simulators.StateVector.EvolutionStrategy.Complex do
  @moduledoc false

  @behaviour NxQuantum.Adapters.Simulators.StateVector.EvolutionStrategy

  alias NxQuantum.Adapters.Simulators.StateVector.State
  alias NxQuantum.Circuit

  @impl true
  @spec applicable?(Circuit.t()) :: boolean()
  def applicable?(%Circuit{}), do: true

  @impl true
  @spec evolve(Circuit.t()) :: Nx.Tensor.t()
  def evolve(%Circuit{} = circuit) do
    circuit.qubits
    |> State.initial_state()
    |> State.apply_operations(circuit.operations)
  end
end
