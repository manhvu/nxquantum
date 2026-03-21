defmodule NxQuantum.EstimatorTest do
  use ExUnit.Case, async: true

  alias NxQuantum.Circuit
  alias NxQuantum.Estimator
  alias NxQuantum.Estimator.Result
  alias NxQuantum.Gates

  describe "expectation_result/2" do
    test "returns typed error for unsupported runtime profile" do
      circuit = [qubits: 1] |> Circuit.new() |> Map.put(:measurement, %{observable: :pauli_z, wire: 0})

      assert {:error, %{code: :unsupported_runtime_profile}} =
               Estimator.expectation_result(circuit, runtime_profile: :unknown_profile)
    end

    test "returns typed error for strict unavailable runtime" do
      circuit = [qubits: 1] |> Circuit.new() |> Map.put(:measurement, %{observable: :pauli_z, wire: 0})

      assert {:error, %{code: :backend_unavailable}} =
               Estimator.expectation_result(circuit,
                 runtime_profile: :nvidia_gpu_compiled,
                 fallback_policy: :strict,
                 runtime_available?: false
               )
    end

    test "supports deterministic shot estimation with seed" do
      circuit = [qubits: 1] |> Circuit.new() |> Map.put(:measurement, %{observable: :pauli_z, wire: 0})

      {:ok, a} = Estimator.expectation_result(circuit, shots: 128, seed: 123)
      {:ok, b} = Estimator.expectation_result(circuit, shots: 128, seed: 123)

      assert Nx.to_number(a) == Nx.to_number(b)
    end

    test "depolarizing noise shrinks absolute expectation magnitude" do
      circuit = [qubits: 1] |> Circuit.new() |> Map.put(:measurement, %{observable: :pauli_z, wire: 0})

      {:ok, ideal} = Estimator.expectation_result(circuit)
      {:ok, noisy} = Estimator.expectation_result(circuit, noise: [depolarizing: 0.2])

      assert abs(Nx.to_number(noisy)) < abs(Nx.to_number(ideal))
    end

    test "amplitude damping biases expectation toward ground state" do
      circuit =
        [qubits: 1]
        |> Circuit.new()
        |> Gates.ry(0, theta: :math.pi())
        |> Map.put(:measurement, %{observable: :pauli_z, wire: 0})

      {:ok, ideal} = Estimator.expectation_result(circuit)
      {:ok, noisy} = Estimator.expectation_result(circuit, noise: [amplitude_damping: 0.2])

      assert Nx.to_number(ideal) < -0.99
      assert Nx.to_number(noisy) > Nx.to_number(ideal)
    end
  end

  describe "run/2" do
    test "returns typed result for multi-observable batch" do
      circuit = Circuit.new(qubits: 1)

      assert {:ok, %Result{} = result} =
               Estimator.run(circuit, observables: [:pauli_x, :pauli_y, :pauli_z], wire: 0)

      assert Nx.shape(result.values) == {3}
      assert result.metadata.mode == :estimator
      assert length(result.metadata.observables) == 3
    end

    test "returns typed error for invalid observable" do
      circuit = Circuit.new(qubits: 1)

      assert {:error, %{code: :unsupported_observable, observable: :unsupported}} =
               Estimator.run(circuit, observables: [:unsupported], wire: 0)
    end

    test "returns typed error for invalid wire schema" do
      circuit = Circuit.new(qubits: 1)

      assert {:error, %{code: :invalid_measurement_wire}} =
               Estimator.run(circuit, observables: [:pauli_z], wire: -1)
    end
  end

  describe "batched_expectation/3" do
    test "returns deterministic batch values for fixed inputs" do
      builder = fn theta ->
        [qubits: 1]
        |> Circuit.new()
        |> Gates.ry(0, theta: theta)
      end

      batch = Nx.tensor([0.0, 1.0, 2.0])

      assert {:ok, a} = Estimator.batched_expectation(builder, batch, observable: :pauli_z, wire: 0)
      assert {:ok, b} = Estimator.batched_expectation(builder, batch, observable: :pauli_z, wire: 0)
      assert Nx.to_flat_list(a) == Nx.to_flat_list(b)
      assert Nx.shape(a) == {3}
    end

    test "returns typed error for invalid batch shape" do
      builder = fn theta -> [qubits: 1] |> Circuit.new() |> Gates.ry(0, theta: theta) end

      assert {:error, %{code: :invalid_batch_shape, received: {2, 2}}} =
               Estimator.batched_expectation(builder, Nx.tensor([[0.1, 0.2], [0.3, 0.4]]),
                 observable: :pauli_z,
                 wire: 0
               )
    end

    test "parallel batch execution preserves deterministic values and ordering" do
      builder = fn theta ->
        [qubits: 1]
        |> Circuit.new()
        |> Gates.ry(0, theta: theta)
      end

      batch = Nx.tensor([0.0, 0.3, 0.7, 1.1, 1.5, 1.9, 2.2, 2.6], type: {:f, 32})

      assert {:ok, sequential} =
               Estimator.batched_expectation(builder, batch,
                 observable: :pauli_z,
                 wire: 0
               )

      assert {:ok, parallel} =
               Estimator.batched_expectation(builder, batch,
                 observable: :pauli_z,
                 wire: 0,
                 parallel: true,
                 max_concurrency: 4
               )

      assert Nx.to_flat_list(sequential) == Nx.to_flat_list(parallel)
    end
  end
end
