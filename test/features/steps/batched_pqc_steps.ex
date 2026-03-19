defmodule NxQuantum.Features.Steps.BatchedPqcSteps do
  @moduledoc false
  # credo:disable-for-this-file Credo.Check.Refactor.Nesting

  @behaviour NxQuantum.Features.FeatureSteps

  import ExUnit.Assertions

  alias NxQuantum.Circuit
  alias NxQuantum.Estimator
  alias NxQuantum.Features.StepExecutor
  alias NxQuantum.Gates
  alias NxQuantum.Sampler
  alias NxQuantum.TestSupport.Helpers

  @impl true
  def feature, do: "batched_pqc.feature"

  @impl true
  def execute(step, ctx) do
    handlers = [&handle_setup/2, &handle_execution/2, &handle_assertions/2]

    case StepExecutor.run(step, ctx, handlers) do
      {:handled, updated} -> updated
      :unhandled -> raise "unhandled step: #{step.text}"
    end
  end

  defp handle_setup(%{text: text}, ctx) do
    cond do
      text == "a fixed variational circuit topology" ->
        builder = fn theta ->
          [qubits: 1]
          |> Circuit.new()
          |> Gates.ry(0, theta: theta)
        end

        {:handled, Map.put(ctx, :circuit_builder, builder)}

      text == "batched parameters are provided as an Nx tensor" ->
        {:handled, Map.put(ctx, :batched_theta, Nx.tensor([0.0, 1.2, 2.1]))}

      text =~ ~r/^batch size is / ->
        size = text |> Helpers.parse_quoted_number() |> trunc()
        {:handled, Map.put(ctx, :batched_theta, Nx.tensor(Enum.take([0.4], size)))}

      text =~ ~r/^shots is / ->
        {:handled, Map.put(ctx, :shots, trunc(Helpers.parse_quoted_number(text)))}

      text =~ ~r/^seed is / ->
        {:handled, Map.put(ctx, :seed, trunc(Helpers.parse_quoted_number(text)))}

      text == "parameter tensor shape does not match circuit parameter schema" ->
        {:handled, Map.put(ctx, :invalid_batch, Nx.tensor([[0.1, 0.2], [0.3, 0.4]]))}

      true ->
        :unhandled
    end
  end

  defp handle_execution(%{text: text}, ctx) do
    cond do
      text == "I compute expectations in batched mode" ->
        {:ok, values} =
          Estimator.batched_expectation(
            fn theta -> ctx.circuit_builder.(theta) end,
            ctx.batched_theta,
            observable: :pauli_z,
            wire: 0
          )

        {:handled, Map.put(ctx, :batched_values, Nx.to_flat_list(values))}

      text == "I compute the same expectations using a scalar loop baseline" ->
        baseline =
          ctx.batched_theta
          |> Nx.to_flat_list()
          |> Enum.map(fn theta ->
            theta
            |> Nx.tensor()
            |> ctx.circuit_builder.()
            |> Circuit.expectation(observable: :pauli_z, wire: 0)
            |> Nx.to_number()
          end)

        {:handled, Map.put(ctx, :baseline_values, baseline)}

      text == "I run batched execution" ->
        {:ok, values} =
          Estimator.batched_expectation(
            fn theta -> ctx.circuit_builder.(theta) end,
            ctx.batched_theta,
            observable: :pauli_z,
            wire: 0
          )

        {:handled, Map.put(ctx, :batched_values, Nx.to_flat_list(values))}

      text == "I run batched Sampler twice" ->
        {:ok, sample_a} =
          Sampler.batched_run(
            fn theta -> ctx.circuit_builder.(theta) end,
            ctx.batched_theta,
            shots: ctx.shots,
            seed: ctx.seed
          )

        {:ok, sample_b} =
          Sampler.batched_run(
            fn theta -> ctx.circuit_builder.(theta) end,
            ctx.batched_theta,
            shots: ctx.shots,
            seed: ctx.seed
          )

        counts_a = Enum.map(sample_a, & &1.counts)
        counts_b = Enum.map(sample_b, & &1.counts)
        {:handled, ctx |> Map.put(:sample_a, counts_a) |> Map.put(:sample_b, counts_b)}

      text == "I run batched Estimator" ->
        error =
          Estimator.batched_expectation(
            fn theta -> ctx.circuit_builder.(theta) end,
            ctx.invalid_batch,
            observable: :pauli_z,
            wire: 0
          )

        {:handled, Map.put(ctx, :error_result, error)}

      true ->
        :unhandled
    end
  end

  defp handle_assertions(%{text: text}, ctx) do
    cond do
      text == "batched and scalar results match within tolerance" ->
        ctx.batched_values
        |> Enum.zip(ctx.baseline_values)
        |> Enum.each(fn {a, b} -> assert_in_delta a, b, 1.0e-6 end)

        {:handled, ctx}

      text == "output values match scalar API values" ->
        [theta] = Nx.to_flat_list(ctx.batched_theta)

        scalar =
          theta
          |> Nx.tensor()
          |> ctx.circuit_builder.()
          |> Circuit.expectation(observable: :pauli_z, wire: 0)
          |> Nx.to_number()

        assert_in_delta hd(ctx.batched_values), scalar, 1.0e-6
        {:handled, ctx}

      text == "output shape follows the batch contract" ->
        assert length(ctx.batched_values) == elem(Nx.shape(ctx.batched_theta), 0)
        {:handled, ctx}

      text == "both sampled batch outputs are identical" ->
        assert ctx.sample_a == ctx.sample_b
        {:handled, ctx}

      text == "error \"invalid_batch_shape\" is returned" ->
        assert {:error, %{code: :invalid_batch_shape}} = ctx.error_result
        {:handled, ctx}

      text == "error metadata includes expected and received shapes" ->
        assert {:error, %{expected: _, received: _}} = ctx.error_result
        {:handled, ctx}

      true ->
        :unhandled
    end
  end
end
