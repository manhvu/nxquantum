defmodule NxQuantum.Application.ExecuteCircuit do
  @moduledoc """
  Application service that executes circuit use-cases through ports.
  """

  alias NxQuantum.Circuit
  alias NxQuantum.Runtime.SimulatorResolver

  @spec expectation(Circuit.t(), keyword()) :: Nx.Tensor.t()
  def expectation(%Circuit{} = circuit, opts \\ []) do
    simulator = Keyword.get_lazy(opts, :simulator, &SimulatorResolver.default/0)
    backend_opts = Keyword.get(opts, :backend_opts, [])
    simulator_opts = opts |> Keyword.drop([:simulator, :backend_opts]) |> Keyword.merge(backend_opts)

    simulator.expectation(circuit, simulator_opts)
  end

  @spec expectations(Circuit.t(), [map()], keyword()) :: Nx.Tensor.t()
  def expectations(%Circuit{} = circuit, observable_specs, opts \\ []) when is_list(observable_specs) do
    simulator = Keyword.get_lazy(opts, :simulator, &SimulatorResolver.default/0)
    backend_opts = Keyword.get(opts, :backend_opts, [])
    simulator_opts = opts |> Keyword.drop([:simulator, :backend_opts]) |> Keyword.merge(backend_opts)

    if function_exported?(simulator, :expectations, 3) do
      simulator.expectations(circuit, observable_specs, simulator_opts)
    else
      observable_specs
      |> Enum.map(fn %{observable: observable, wire: wire} ->
        measured = %{circuit | measurement: %{observable: observable, wire: wire}}
        simulator.expectation(measured, simulator_opts)
      end)
      |> case do
        [] -> Nx.tensor([], type: {:f, 32})
        values -> Nx.stack(values)
      end
    end
  end
end
