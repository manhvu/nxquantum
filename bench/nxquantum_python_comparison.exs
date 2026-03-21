alias NxQuantum.Circuit
alias NxQuantum.Estimator
alias NxQuantum.Gates

iterations =
  case System.argv() do
    [value | _] ->
      case Integer.parse(value) do
        {parsed, ""} when parsed > 0 -> parsed
        _ -> 1000
      end

    _ ->
      1000
  end

warmup = min(100, iterations)

circuit =
  [qubits: 2]
  |> Circuit.new()
  |> Gates.h(0)
  |> Gates.cnot(control: 0, target: 1)
  |> Gates.ry(1, theta: Nx.tensor(0.3))

run_once = fn ->
  case Estimator.expectation_result(circuit, observable: :pauli_z, wire: 1, runtime_profile: :cpu_portable) do
    {:ok, value} -> value
    {:error, reason} -> raise "NxQuantum benchmark failed: #{inspect(reason)}"
  end
end

for _ <- 1..warmup do
  _ = run_once.()
end

{microseconds, last_value} =
  :timer.tc(fn ->
    Enum.reduce(1..iterations, nil, fn _, _acc ->
      run_once.()
    end)
  end)

total_ms = microseconds / 1000.0
per_op_ms = total_ms / iterations
ops_s = iterations / (microseconds / 1_000_000.0)
numeric_value = Nx.to_number(last_value)

IO.puts(
  "NXQ_BENCH total_ms=#{Float.round(total_ms, 6)} per_op_ms=#{Float.round(per_op_ms, 6)} ops_s=#{Float.round(ops_s, 6)} value=#{Float.round(numeric_value, 10)}"
)
