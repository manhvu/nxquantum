defmodule NxQuantum.Ports.Simulator do
  @moduledoc """
  Port for simulation engines that execute circuit operations.
  """

  alias NxQuantum.Circuit
  alias NxQuantum.GateOperation

  @callback expectation(Circuit.t(), keyword()) :: Nx.Tensor.t()
  @callback expectations(Circuit.t(), [map()], keyword()) :: Nx.Tensor.t()
  @callback apply_gates(Nx.Tensor.t(), [GateOperation.t()], keyword()) :: Nx.Tensor.t()

  @optional_callbacks expectations: 3
end
