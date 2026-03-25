defmodule NxQuantum.Estimator.RuntimeAutoSelector do
  @moduledoc false

  alias NxQuantum.Estimator.SampledExpval.ExecutionStrategy
  alias NxQuantum.Runtime
  alias NxQuantum.Runtime.Detection

  @spec choose(keyword(), keyword()) :: %{profile: Runtime.profile(), reason: atom()}
  def choose(opts, context_opts \\ []) do
    case Keyword.get(context_opts, :kind, :scalar) do
      :batch ->
        choose_for_batch(opts, context_opts)

      :sampled ->
        choose_for_sampled(opts, context_opts)

      _ ->
        choose_general(opts)
    end
  end

  defp choose_for_batch(opts, context_opts) do
    qubits = Keyword.get(context_opts, :qubits, 0)
    observable_specs = Keyword.get(context_opts, :observable_specs, [])

    if fused_single_wire_shape?(qubits, observable_specs) do
      %{profile: Runtime.profile!(:cpu_portable), reason: :portable_preferred_fused_single_wire_batch}
    else
      choose_general(opts)
    end
  end

  defp choose_for_sampled(opts, context_opts) do
    unit_count = Keyword.get(context_opts, :sampled_unit_count, 0)
    entry_count = Keyword.get(context_opts, :sampled_entry_count, 0)
    strategy = ExecutionStrategy.select(unit_count, entry_count, opts)

    if strategy.mode == :scalar do
      %{profile: Runtime.profile!(:cpu_portable), reason: :portable_preferred_sampled_scalar}
    else
      choose_general(opts)
    end
  end

  defp choose_general(opts) do
    if Detection.runtime_available?(:cpu_compiled, opts) do
      %{profile: Runtime.profile!(:cpu_compiled), reason: :compiled_preferred_general}
    else
      %{profile: Runtime.profile!(:cpu_portable), reason: :portable_fallback_compiled_unavailable}
    end
  end

  defp fused_single_wire_shape?(qubits, observable_specs) when is_integer(qubits) and is_list(observable_specs) do
    qubits <= 12 and
      length(observable_specs) >= 24 and
      Enum.all?(observable_specs, fn
        %{observable: observable, wire: wire}
        when observable in [:pauli_x, :pauli_y, :pauli_z] and is_integer(wire) ->
          wire >= 0 and wire < qubits

        _ ->
          false
      end)
  end
end
