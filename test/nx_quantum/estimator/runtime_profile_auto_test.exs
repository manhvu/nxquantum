defmodule NxQuantum.Estimator.RuntimeProfileAutoTest do
  use ExUnit.Case, async: true

  alias NxQuantum.Estimator.RuntimeProfile

  test "auto batch selection prefers portable on fused-single-wire workloads" do
    opts = [runtime_profile: :auto, capabilities: %{cpu_compiled: true, cpu_portable: true}]

    assert {:ok, selection} =
             RuntimeProfile.resolve_with_context(
               opts,
               kind: :batch,
               qubits: 8,
               observable_specs: Enum.map(0..47, fn _ -> %{observable: :pauli_x, wire: 0} end)
             )

    assert selection.selected_profile == :cpu_portable
    assert selection.reason == :portable_preferred_fused_single_wire_batch
  end

  test "auto sampled selection prefers portable for scalar-small workloads" do
    opts = [
      runtime_profile: :auto,
      capabilities: %{cpu_compiled: true, cpu_portable: true},
      sampled_parallel_mode: :auto,
      parallel_sampled_terms: true,
      parallel_sampled_terms_threshold: 2,
      sampled_parallel_min_work: 8192
    ]

    assert {:ok, selection} =
             RuntimeProfile.resolve_with_context(
               opts,
               kind: :sampled,
               sampled_unit_count: 4,
               sampled_entry_count: 4
             )

    assert selection.selected_profile == :cpu_portable
    assert selection.reason == :portable_preferred_sampled_scalar
  end

  test "auto general selection prefers compiled when available" do
    opts = [runtime_profile: :auto, capabilities: %{cpu_compiled: true, cpu_portable: true}]

    assert {:ok, selection} = RuntimeProfile.resolve_with_context(opts, kind: :scalar, qubits: 1)
    assert selection.selected_profile == :cpu_compiled
    assert selection.reason == :compiled_preferred_general
  end
end
