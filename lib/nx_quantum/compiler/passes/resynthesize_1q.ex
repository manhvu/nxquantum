defmodule NxQuantum.Compiler.Passes.Resynthesize1Q do
  @moduledoc false

  alias NxQuantum.Adapters.Simulators.StateVector.Matrices
  alias NxQuantum.GateOperation

  @single_qubit_gates [:h, :x, :y, :z, :rx, :ry, :rz]
  @default_gate_costs %{h: 2.0, x: 1.0, y: 1.0, z: 1.0, rx: 2.0, ry: 2.0, rz: 1.0}
  @default_tolerance 1.0e-6
  @default_theta_epsilon 1.0e-10

  @spec run([GateOperation.t()], keyword()) :: [GateOperation.t()]
  def run(operations, opts \\ []) when is_list(operations) do
    operations
    |> rewrite([], opts)
    |> Enum.reverse()
  end

  defp rewrite([], acc, _opts), do: acc

  defp rewrite([op | rest], acc, opts) do
    if single_qubit_gate?(op) do
      {run, tail} = take_single_qubit_run([op | rest], op.wires)
      rewritten = maybe_resynthesize_run(run, opts)
      rewrite(tail, Enum.reverse(rewritten, acc), opts)
    else
      rewrite(rest, [op | acc], opts)
    end
  end

  defp single_qubit_gate?(%GateOperation{name: name, wires: [_wire]}), do: name in @single_qubit_gates
  defp single_qubit_gate?(_), do: false

  defp take_single_qubit_run(operations, wire), do: take_single_qubit_run(operations, wire, [])

  defp take_single_qubit_run([], _wire, acc), do: {Enum.reverse(acc), []}

  defp take_single_qubit_run([%GateOperation{wires: wires} = op | rest], wire, acc)
       when wires == wire and length(wire) == 1 and op.name in @single_qubit_gates do
    take_single_qubit_run(rest, wire, [op | acc])
  end

  defp take_single_qubit_run(operations, _wire, acc), do: {Enum.reverse(acc), operations}

  defp maybe_resynthesize_run(run, _opts) when length(run) < 2, do: run

  defp maybe_resynthesize_run(run, opts) do
    wire = run |> hd() |> Map.fetch!(:wires) |> hd()
    original_unitary = run_unitary(run)
    candidate = synthesize_zyz(original_unitary, wire, opts)
    candidate_unitary = run_unitary(candidate)
    error = unitary_error(original_unitary, candidate_unitary)
    tolerance = Keyword.get(opts, :resynthesis_tolerance, @default_tolerance)

    if error <= tolerance and beneficial_replacement?(run, candidate, opts) do
      candidate
    else
      run
    end
  end

  defp beneficial_replacement?(run, candidate, opts) do
    run_cost = sequence_cost(run, opts)
    candidate_cost = sequence_cost(candidate, opts)

    candidate_cost < run_cost or (candidate_cost == run_cost and length(candidate) < length(run))
  end

  defp sequence_cost(operations, opts) do
    gate_costs = Keyword.get(opts, :gate_costs, @default_gate_costs)

    Enum.reduce(operations, 0.0, fn %GateOperation{name: name}, acc ->
      acc + Map.get(gate_costs, name, 1.0)
    end)
  end

  defp synthesize_zyz(unitary, wire, opts) do
    tolerance = Keyword.get(opts, :resynthesis_theta_epsilon, @default_theta_epsilon)
    su2 = remove_global_phase(unitary)
    a = matrix_element(su2, 0, 0)
    b = matrix_element(su2, 0, 1)
    c = matrix_element(su2, 1, 0)

    abs_a = abs_complex(a)
    abs_c = abs_complex(c)
    beta = 2.0 * :math.atan2(abs_c, abs_a)

    {alpha, gamma} =
      cond do
        abs_c < tolerance ->
          {0.0, -2.0 * angle(a)}

        abs_a < tolerance ->
          {2.0 * angle(c), 0.0}

        true ->
          phase_a = angle(a)
          phase_c = angle(c)
          phase_b = angle(Nx.negate(b))
          {phase_c - phase_a, phase_b - phase_a}
      end

    Enum.filter([rz_gate(wire, alpha), ry_gate(wire, beta), rz_gate(wire, gamma)], & &1)
  end

  defp rz_gate(wire, theta) do
    theta = normalize_angle(theta)
    if abs(theta) < @default_theta_epsilon, do: nil, else: GateOperation.new(:rz, [wire], theta: theta)
  end

  defp ry_gate(wire, theta) do
    theta = normalize_angle(theta)
    if abs(theta) < @default_theta_epsilon, do: nil, else: GateOperation.new(:ry, [wire], theta: theta)
  end

  defp remove_global_phase(unitary) do
    det = determinant(unitary)
    phase = angle(det) / 2.0
    phase_factor = complex_scalar(:math.cos(-phase), :math.sin(-phase))
    Nx.multiply(unitary, phase_factor)
  end

  defp run_unitary([]), do: identity_matrix()

  defp run_unitary(operations) do
    Enum.reduce(operations, identity_matrix(), fn op, acc ->
      Nx.dot(Matrices.single_qubit_gate_matrix(op), acc)
    end)
  end

  defp unitary_error(original, candidate) do
    u_dag = Nx.conjugate(Nx.transpose(original))
    product = Nx.dot(u_dag, candidate)
    overlap = Nx.add(matrix_element(product, 0, 0), matrix_element(product, 1, 1))
    phase = angle(overlap)
    aligned_candidate = Nx.multiply(candidate, complex_scalar(:math.cos(-phase), :math.sin(-phase)))
    diff = Nx.subtract(original, aligned_candidate)

    diff
    |> Nx.abs()
    |> Nx.pow(2)
    |> Nx.sum()
    |> Nx.to_number()
    |> :math.sqrt()
  end

  defp determinant(matrix) do
    a = matrix_element(matrix, 0, 0)
    b = matrix_element(matrix, 0, 1)
    c = matrix_element(matrix, 1, 0)
    d = matrix_element(matrix, 1, 1)
    Nx.subtract(Nx.multiply(a, d), Nx.multiply(b, c))
  end

  defp matrix_element(matrix, row, col) do
    matrix
    |> Nx.slice([row, col], [1, 1])
    |> Nx.reshape({})
  end

  defp angle(value) do
    value
    |> Nx.imag()
    |> Nx.to_number()
    |> :math.atan2(value |> Nx.real() |> Nx.to_number())
  end

  defp abs_complex(value), do: value |> Nx.abs() |> Nx.to_number()

  defp complex_scalar(real, imag) do
    Nx.complex(Nx.tensor(real, type: {:f, 64}), Nx.tensor(imag, type: {:f, 64}))
  end

  defp identity_matrix do
    Nx.complex(
      Nx.tensor([[1.0, 0.0], [0.0, 1.0]], type: {:f, 64}),
      Nx.tensor([[0.0, 0.0], [0.0, 0.0]], type: {:f, 64})
    )
  end

  defp normalize_angle(angle) do
    two_pi = 2.0 * :math.pi()
    shifted = :math.fmod(angle + :math.pi(), two_pi)
    wrapped = if shifted < 0.0, do: shifted + two_pi, else: shifted
    wrapped - :math.pi()
  end
end
