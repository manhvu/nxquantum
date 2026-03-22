defmodule NxQuantum.Adapters.Simulators.StateVector do
  @moduledoc """
  State-vector simulator adapter.

  Gate application and expectation primitives delegate to `Nx.Defn` kernels in
  `NxQuantum.Adapters.Simulators.StateVector.State`.
  """

  @behaviour NxQuantum.Ports.Simulator

  alias NxQuantum.Adapters.Simulators.StateVector.EvolutionStrategy
  alias NxQuantum.Adapters.Simulators.StateVector.Matrices
  alias NxQuantum.Adapters.Simulators.StateVector.State
  alias NxQuantum.Circuit
  alias NxQuantum.GateOperation

  @type state_vector :: Nx.Tensor.t()

  @impl true
  @spec expectation(Circuit.t(), keyword()) :: Nx.Tensor.t()
  def expectation(%Circuit{measurement: nil}, _opts) do
    raise ArgumentError, "measurement not set; call Circuit.expectation/2 with observable and wire"
  end

  def expectation(%Circuit{} = circuit, _opts) do
    %{observable: observable, wire: wire} = circuit.measurement
    state = EvolutionStrategy.evolve(circuit)
    value = expectation_for_observable(state, observable, wire, circuit.qubits)
    Nx.as_type(value, {:f, 32})
  end

  @impl true
  @spec apply_gates(state_vector(), [GateOperation.t()], keyword()) :: state_vector()
  def apply_gates(%Nx.Tensor{} = state, operations, _opts) when is_list(operations) do
    State.apply_operations(state, operations)
  end

  defp expectation_for_observable(state, :pauli_z, wire, qubits), do: State.expectation_pauli_z(state, wire, qubits)

  defp expectation_for_observable(state, observable, wire, qubits) do
    observable_matrix = Matrices.observable_matrix(observable, wire, qubits)
    State.expectation_from_state(state, observable_matrix)
  end
end
