alias NxQuantum.Circuit
alias NxQuantum.Estimator
alias NxQuantum.Gates

parse_arg = fn argv, index, default ->
  argv
  |> Enum.at(index)
  |> case do
    nil ->
      default

    raw ->
      case Integer.parse(raw) do
        {value, ""} when value > 0 -> value
        _ -> default
      end
  end
end

args = System.argv()
iterations = parse_arg.(args, 0, 2000)
observable_count = parse_arg.(args, 1, 48)
qubits = parse_arg.(args, 2, 8)

circuit =
  [qubits: qubits]
  |> Circuit.new()
  |> Gates.h(0)
  |> Gates.cnot(control: 0, target: 1)
  |> Gates.ry(2, theta: Nx.tensor(0.31))
  |> Gates.rx(3, theta: Nx.tensor(0.19))
  |> Gates.rz(4, theta: Nx.tensor(0.27))
  |> Gates.cnot(control: 2, target: 5)
  |> Gates.cnot(control: 5, target: 6)
  |> Gates.ry(7, theta: Nx.tensor(0.11))

observable_cycle = [:pauli_x, :pauli_y, :pauli_z]

observables =
  0..(observable_count - 1)
  |> Enum.map(fn index ->
    %{observable: Enum.at(observable_cycle, rem(index, 3)), wire: rem(index, qubits)}
  end)

measure = fn fun ->
  {microseconds, _} = :timer.tc(fun)
  total_ms = microseconds / 1000.0
  per_op_ms = total_ms / iterations
  ops_s = iterations / (microseconds / 1_000_000.0)
  %{total_ms: total_ms, per_op_ms: per_op_ms, ops_s: ops_s}
end

batch_sequential =
  measure.(fn ->
    Enum.each(1..iterations, fn _ ->
      {:ok, _} =
        Estimator.run(circuit,
          observables: observables,
          runtime_profile: :cpu_portable,
          parallel_observables: false
        )
    end)
  end)

batch_parallel =
  measure.(fn ->
    Enum.each(1..iterations, fn _ ->
      {:ok, _} =
        Estimator.run(circuit,
          observables: observables,
          runtime_profile: :cpu_portable,
          parallel_observables: true,
          parallel_observables_threshold: 16,
          max_concurrency: System.schedulers_online()
        )
    end)
  end)

scalar_loop =
  measure.(fn ->
    Enum.each(1..iterations, fn _ ->
      Enum.each(observables, fn %{observable: observable, wire: wire} ->
        {:ok, _} =
          Estimator.expectation_result(circuit,
            observable: observable,
            wire: wire,
            runtime_profile: :cpu_portable
          )
      end)
    end)
  end)

for {label, stats} <- [batch_sequential: batch_sequential, batch_parallel: batch_parallel, scalar_loop: scalar_loop] do
  IO.puts(
    "EST_BATCH_STRATEGY_BENCH label=#{label} iterations=#{iterations} observable_count=#{observable_count} qubits=#{qubits} total_ms=#{Float.round(stats.total_ms, 6)} per_op_ms=#{Float.round(stats.per_op_ms, 6)} ops_s=#{Float.round(stats.ops_s, 6)}"
  )
end

IO.puts(
  "EST_BATCH_STRATEGY_SPEEDUP scalar_over_batch_seq=#{Float.round(scalar_loop.total_ms / batch_sequential.total_ms, 6)} scalar_over_batch_par=#{Float.round(scalar_loop.total_ms / batch_parallel.total_ms, 6)}"
)
