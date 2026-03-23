defmodule NxQuantum.Estimator.Batch.Strategies.ScalarFallback do
  @moduledoc false

  @behaviour NxQuantum.Estimator.Batch.Strategy

  alias NxQuantum.Circuit
  alias NxQuantum.Estimator.ResultBuilder
  alias NxQuantum.Estimator.Scalar

  @impl true
  @spec run(Circuit.t(), [map()], keyword()) :: {:ok, NxQuantum.Estimator.Result.t()} | {:error, map()}
  def run(circuit, observable_specs, opts) do
    observable_specs
    |> scalar_results(circuit, opts)
    |> to_batch_result(observable_specs, opts)
  end

  defp scalar_results(observable_specs, circuit, opts) do
    Enum.map(observable_specs, fn %{observable: observable, wire: wire} ->
      Scalar.run(circuit, Keyword.merge(opts, observable: observable, wire: wire))
    end)
  end

  defp to_batch_result(results, observable_specs, opts) do
    case Enum.find(results, &match?({:error, _}, &1)) do
      {:error, metadata} ->
        {:error, metadata}

      nil ->
        values =
          results
          |> Enum.map(fn {:ok, tensor} -> Nx.to_number(tensor) end)
          |> Nx.tensor(type: {:f, 32})

        {:ok, ResultBuilder.build(values, observable_specs, opts)}
    end
  end
end
