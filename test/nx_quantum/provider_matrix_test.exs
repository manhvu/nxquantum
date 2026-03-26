defmodule NxQuantum.ProviderMatrixTest do
  use ExUnit.Case, async: true

  alias NxQuantum.TestSupport.ProviderMatrix

  test "entries are deterministically ordered by provider id" do
    ids = Enum.map(ProviderMatrix.entries(), & &1.id)
    assert ids == Enum.sort(ids)
  end

  test "entries include required fields" do
    for entry <- ProviderMatrix.entries() do
      assert is_atom(entry.id)
      assert is_binary(entry.label)
      assert is_atom(entry.adapter)
      assert is_binary(entry.target)
      assert is_map(entry.provider_config)
      assert is_list(entry.suite_tags)
    end
  end

  test "suite filtering is deterministic and non-empty for known suites" do
    suites = [
      :capability_contracts,
      :cross_platform,
      :observability,
      :live_execution,
      :transport_readiness,
      :batched_primitives
    ]

    for suite <- suites do
      first = ProviderMatrix.entries_for(suite)
      second = ProviderMatrix.entries_for(suite)

      refute first == []
      assert first == second
      assert Enum.all?(first, &(suite in &1.suite_tags))
    end
  end

  test "entry! returns provider entry by id" do
    assert %{id: :ibm_runtime, label: "IBM Runtime"} = ProviderMatrix.entry!(:ibm_runtime)
    assert %{id: :aws_braket, label: "AWS Braket"} = ProviderMatrix.entry!(:aws_braket)
    assert %{id: :azure_quantum, label: "Azure Quantum"} = ProviderMatrix.entry!(:azure_quantum)
  end

  test "entry! raises for unknown provider id" do
    assert_raise ArgumentError, ~r/unknown provider id/, fn ->
      ProviderMatrix.entry!(:unknown_provider)
    end
  end
end
