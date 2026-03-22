defmodule NxQuantum.Adapters.Simulators.StateVector.EvolutionStrategy.RealPauliZ do
  @moduledoc false

  @behaviour NxQuantum.Adapters.Simulators.StateVector.EvolutionStrategy

  alias NxQuantum.Adapters.Simulators.StateVector.State
  alias NxQuantum.Circuit

  @impl true
  @spec applicable?(Circuit.t()) :: boolean()
  def applicable?(%Circuit{measurement: %{observable: :pauli_z}, operations: operations}) do
    State.real_path_eligible?(operations)
  end

  def applicable?(%Circuit{}), do: false

  @impl true
  @spec evolve(Circuit.t()) :: Nx.Tensor.t()
  def evolve(%Circuit{} = circuit) do
    circuit.qubits
    |> State.initial_state_real()
    |> State.apply_operations_real(circuit.operations)
  end
end
