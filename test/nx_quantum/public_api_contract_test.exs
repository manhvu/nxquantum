defmodule NxQuantum.PublicApiContractTest do
  use ExUnit.Case, async: true

  alias NxQuantum.Circuit
  alias NxQuantum.Estimator
  alias NxQuantum.Gates
  alias NxQuantum.Kernels
  alias NxQuantum.Runtime

  describe "stable facade exports" do
    test "core modules expose v0.2 stable contract functions" do
      assert function_exported?(Circuit, :new, 1)
      assert function_exported?(Circuit, :bind, 2)
      assert function_exported?(Circuit, :expectation, 2)

      assert function_exported?(Gates, :h, 2)
      assert function_exported?(Gates, :rx, 3)
      assert function_exported?(Gates, :ry, 3)
      assert function_exported?(Gates, :rz, 3)
      assert function_exported?(Gates, :cnot, 2)

      assert function_exported?(Runtime, :supported_profiles, 0)
      assert function_exported?(Runtime, :profile!, 1)
      assert function_exported?(Runtime, :resolve, 2)
      assert function_exported?(Runtime, :capabilities, 1)

      assert function_exported?(Estimator, :expectation, 2)
      assert function_exported?(Estimator, :expectation_result, 2)
      assert function_exported?(Estimator, :run, 2)
    end
  end

  describe "experimental facade exports" do
    test "advanced modules expose explicit entrypoints" do
      assert function_exported?(NxQuantum.Grad, :value_and_grad, 3)
      assert function_exported?(NxQuantum.Compiler, :optimize, 2)
      assert function_exported?(Kernels, :matrix, 2)
    end
  end

  test "stable expectation_result return contract is typed tuple" do
    circuit = Circuit.new(qubits: 1)

    assert {:ok, %Nx.Tensor{}} =
             Estimator.expectation_result(circuit, observable: :pauli_z, wire: 0)
  end

  test "runtime resolve return contract is deterministic typed tuple" do
    assert {:ok, %{id: :cpu_portable}} = Runtime.resolve(:cpu_portable, runtime_available?: true)

    assert {:error, %{code: :unsupported_runtime_profile}} =
             Runtime.resolve(:unknown_profile, runtime_available?: false)
  end
end
