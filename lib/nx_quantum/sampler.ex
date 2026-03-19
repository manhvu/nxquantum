defmodule NxQuantum.Sampler do
  @moduledoc """
  Sampler primitive facade.

  v0.3 scope:
  - deterministic shot sampling contract,
  - typed sampler result object,
  - simple probability/count outputs for foundational workflows.
  """

  alias NxQuantum.Circuit
  alias NxQuantum.Estimator
  alias NxQuantum.Sampler.Engine
  alias NxQuantum.Sampler.Options
  alias NxQuantum.Sampler.Result
  alias NxQuantum.Sampler.ResultBuilder

  @spec run(Circuit.t(), keyword()) :: {:ok, Result.t()} | {:error, map()}
  def run(%Circuit{} = circuit, opts \\ []) do
    with {:ok, config} <- Options.normalize(opts),
         {:ok, expectation} <-
           Estimator.expectation_result(circuit, Options.estimator_opts(config)) do
      value = Nx.to_number(expectation)
      {zero_count, one_count} = Engine.sample_counts(value, config.shots, config.seed)
      {:ok, ResultBuilder.build(config, zero_count, one_count)}
    end
  end

  @spec batched_run((Nx.Tensor.t() -> Circuit.t()), Nx.Tensor.t(), keyword()) ::
          {:ok, [Result.t()]} | {:error, map()}
  def batched_run(circuit_builder, %Nx.Tensor{} = params_batch, opts \\ []) when is_function(circuit_builder, 1) do
    shape = Nx.shape(params_batch)

    if tuple_size(shape) == 1 do
      results =
        params_batch
        |> Nx.to_flat_list()
        |> Enum.map(fn value ->
          value
          |> Nx.tensor()
          |> circuit_builder.()
          |> run(opts)
        end)

      case Enum.find(results, &match?({:error, _}, &1)) do
        {:error, metadata} -> {:error, metadata}
        nil -> {:ok, Enum.map(results, fn {:ok, result} -> result end)}
      end
    else
      {:error, %{code: :invalid_batch_shape, expected: {:batch}, received: shape}}
    end
  end
end
