defmodule NxQuantum.Application.DynamicIR.Interpreter do
  @moduledoc false

  @spec execute(%{nodes: [map()]}, keyword()) :: {:ok, map()} | {:error, map()}
  def execute(validated_ir, opts \\ []) do
    seed = Keyword.get(opts, :seed, 0)

    Enum.reduce_while(Enum.with_index(validated_ir.nodes), {:ok, initial_execution_state()}, fn {node, idx},
                                                                                                {:ok, state} ->
      case execute_node(node, state, seed, idx) do
        {:ok, next} -> {:cont, {:ok, next}}
        {:error, _} = error -> {:halt, error}
      end
    end)
  end

  defp execute_node(%{type: :measure, register: register} = node, state, seed, idx) do
    bit = measurement_bit(node, seed, idx)

    next =
      state
      |> put_in([:registers, register], bit)
      |> update_in([:metadata, :register_trace], &(&1 ++ [%{register: register, value: bit, node_index: idx}]))

    {:ok, next}
  end

  defp execute_node(%{type: :conditional_gate, register: register} = node, state, _seed, _idx) do
    case Map.fetch(state.registers, register) do
      {:ok, value} ->
        apply_gate? = value == 1
        gate = Map.get(node, :gate, :x)

        next =
          state
          |> update_in(
            [:metadata, :branch_decisions],
            &(&1 ++ [%{register: register, apply_gate?: apply_gate?, gate: gate}])
          )
          |> maybe_add_operation(apply_gate?, gate)

        {:ok, next}

      :error ->
        {:error, %{code: :invalid_dynamic_ir, register: register}}
    end
  end

  defp execute_node(%{type: type}, _state, _seed, _idx) do
    {:error, %{code: :unsupported_dynamic_node, node_type: type}}
  end

  defp execute_node(_invalid, _state, _seed, _idx) do
    {:error, %{code: :invalid_dynamic_ir, reason: :invalid_node_shape}}
  end

  defp initial_execution_state do
    %{
      registers: %{},
      operations_applied: [],
      metadata: %{branch_decisions: [], register_trace: []}
    }
  end

  defp maybe_add_operation(state, true, gate), do: update_in(state, [:operations_applied], &(&1 ++ [gate]))
  defp maybe_add_operation(state, false, _gate), do: state

  defp measurement_bit(%{value: bit}, _seed, _idx) when bit in [0, 1], do: bit

  defp measurement_bit(node, seed, idx) do
    probability_one = Map.get(node, :probability_one, 0.5)
    bucket = rem(:erlang.phash2({seed, idx}), 10_000) / 10_000.0
    if bucket <= probability_one, do: 1, else: 0
  end
end
