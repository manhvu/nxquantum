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
end
