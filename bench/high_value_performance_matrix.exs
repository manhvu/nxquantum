alias NxQuantum.Circuit
alias NxQuantum.Estimator
alias NxQuantum.Gates

scenario = List.first(System.argv()) || "baseline_2q"
iterations = (List.last(System.argv()) || "200") |> String.to_integer()

build_circuit = fn
  "baseline_2q" ->
    Circuit.new(qubits: 2)
    |> Gates.h(0)
    |> Gates.cnot(control: 0, target: 1)
    |> Gates.ry(1, theta: Nx.tensor(0.3))

  "deep_6q" ->
    Circuit.new(qubits: 6)
    |> Gates.h(0)
    |> Gates.cnot(control: 0, target: 1)
    |> Gates.cnot(control: 1, target: 2)
    |> Gates.cnot(control: 2, target: 3)
    |> Gates.cnot(control: 3, target: 4)
    |> Gates.cnot(control: 4, target: 5)
    |> Gates.ry(5, theta: Nx.tensor(0.66))

  "state_reuse_8q_xy" ->
    Circuit.new(qubits: 8)
    |> Gates.h(0)
    |> Gates.cnot(control: 0, target: 1)
    |> Gates.cnot(control: 1, target: 2)
    |> Gates.cnot(control: 2, target: 3)
    |> Gates.cnot(control: 3, target: 4)
    |> Gates.cnot(control: 4, target: 5)
    |> Gates.cnot(control: 5, target: 6)
    |> Gates.cnot(control: 6, target: 7)

  "batch_obs_8q" ->
    Circuit.new(qubits: 8)
    |> Gates.h(0)
    |> Gates.cnot(control: 0, target: 1)
    |> Gates.cnot(control: 1, target: 2)
    |> Gates.cnot(control: 2, target: 3)
    |> Gates.cnot(control: 3, target: 4)
    |> Gates.cnot(control: 4, target: 5)
    |> Gates.cnot(control: 5, target: 6)
    |> Gates.cnot(control: 6, target: 7)

  "sampled_counts_sparse_terms" ->
    Circuit.new(qubits: 2)
    |> Gates.h(0)

  "shot_sweep_param_grid_v1" ->
    Circuit.new(qubits: 2)
    |> Gates.h(0)
    |> Gates.ry(1, theta: Nx.tensor(0.2))
end

circuit = build_circuit.(scenario)
wire = if scenario == "deep_6q", do: 5, else: 1

{us, value} =
  :timer.tc(fn ->
    Enum.reduce(1..iterations, nil, fn _, _ ->
      {:ok, exp} = Estimator.expectation_result(circuit, observable: :pauli_z, wire: wire, runtime_profile: :cpu_portable)
      exp
    end)
  end)

ops_s = iterations / (us / 1_000_000.0)

IO.puts(
  "NXQ_HIGH_VALUE scenario=#{scenario} iterations=#{iterations} total_ms=#{Float.round(us / 1000.0, 6)} ops_s=#{Float.round(ops_s, 6)} value=#{Float.round(Nx.to_number(value), 10)} runtime_profile=cpu_portable"
)
