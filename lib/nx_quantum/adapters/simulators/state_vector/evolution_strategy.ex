defmodule NxQuantum.Adapters.Simulators.StateVector.EvolutionStrategy do
  @moduledoc false

  alias NxQuantum.Adapters.Simulators.StateVector.EvolutionStrategy.Complex
  alias NxQuantum.Adapters.Simulators.StateVector.EvolutionStrategy.RealPauliZ
  alias NxQuantum.Circuit

  @type t :: module()

  @callback applicable?(Circuit.t()) :: boolean()
  @callback evolve(Circuit.t()) :: Nx.Tensor.t()

  @strategies [RealPauliZ, Complex]

  @spec select(Circuit.t()) :: t()
  def select(%Circuit{} = circuit) do
    Enum.find(@strategies, Complex, & &1.applicable?(circuit))
  end

  @spec evolve(Circuit.t()) :: Nx.Tensor.t()
  def evolve(%Circuit{} = circuit) do
    strategy = select(circuit)
    strategy.evolve(circuit)
  end
end
