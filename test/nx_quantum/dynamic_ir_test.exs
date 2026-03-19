defmodule NxQuantum.DynamicIRTest do
  use ExUnit.Case, async: true

  alias NxQuantum.DynamicIR

  test "validate/1 succeeds for valid measure -> conditional dependency" do
    ir = %{
      nodes: [%{type: :measure, register: "c0"}, %{type: :conditional_gate, register: "c0"}],
      registers: MapSet.new(["c0"])
    }

    assert {:ok, validated} = DynamicIR.validate(ir)
    assert validated == ir
  end

  test "validate/1 returns typed error for missing register" do
    ir = %{
      nodes: [%{type: :conditional_gate, register: "c_missing"}],
      registers: MapSet.new()
    }

    assert {:error, %{code: :invalid_dynamic_ir, register: "c_missing"}} = DynamicIR.validate(ir)
  end

  test "execute/2 returns explicit v0.3 boundary error" do
    ir = %{nodes: [%{type: :branch}], registers: MapSet.new()}

    assert {:error, %{code: :dynamic_execution_not_supported, message: message}} = DynamicIR.execute(ir)
    assert String.contains?(message, "future")
  end

  test "execute/2 supported subset is deterministic for same seed" do
    ir = %{
      nodes: [
        %{type: :measure, register: "c0"},
        %{type: :conditional_gate, register: "c0", gate: :x}
      ],
      registers: MapSet.new(["c0"])
    }

    assert {:ok, result_a} = DynamicIR.execute(ir, mode: :supported_v0_4_subset, seed: 42)
    assert {:ok, result_b} = DynamicIR.execute(ir, mode: :supported_v0_4_subset, seed: 42)

    assert result_a == result_b
    assert is_list(result_a.metadata.branch_decisions)
    assert is_list(result_a.metadata.register_trace)
  end

  test "execute/2 supported subset returns unsupported_dynamic_node for unsupported node" do
    ir = %{
      nodes: [%{type: :measure, register: "c0"}, %{type: :phase_kickback}],
      registers: MapSet.new(["c0"])
    }

    assert {:error, %{code: :unsupported_dynamic_node, node_type: :phase_kickback}} =
             DynamicIR.execute(ir, mode: :supported_v0_4_subset, seed: 7)
  end
end
