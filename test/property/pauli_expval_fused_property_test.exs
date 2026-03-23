defmodule NxQuantum.Property.PauliExpvalFusedPropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  import Bitwise

  alias NxQuantum.Adapters.Simulators.StateVector.PauliExpval

  property "fused single-wire evaluation matches per-term expectations and is order-invariant" do
    check all(
            qubits <- integer(3..5),
            state <- normalized_state_generator(qubits),
            terms <- list_of(single_wire_term_generator(qubits), min_length: 24, max_length: 48)
          ) do
      fused_values =
        state
        |> PauliExpval.expectations(terms, qubits,
          parallel_observables: false,
          parallel_observables_threshold: 10_000
        )
        |> Enum.map(&Nx.to_number/1)

      reference_values =
        Enum.map(terms, fn term ->
          state |> PauliExpval.expectation(term, qubits) |> Nx.to_number()
        end)

      fused_values
      |> Enum.zip(reference_values)
      |> Enum.each(fn {fused, reference} ->
        assert_in_delta fused, reference, 1.0e-8
      end)

      shuffled = Enum.shuffle(terms)

      shuffled_values =
        state
        |> PauliExpval.expectations(shuffled, qubits,
          parallel_observables: false,
          parallel_observables_threshold: 10_000
        )
        |> Enum.map(&Nx.to_number/1)

      shuffled_reference =
        Enum.map(shuffled, fn term ->
          state |> PauliExpval.expectation(term, qubits) |> Nx.to_number()
        end)

      shuffled_values
      |> Enum.zip(shuffled_reference)
      |> Enum.each(fn {actual, expected} ->
        assert_in_delta actual, expected, 1.0e-8
      end)
    end
  end

  property "parallel observable reduction remains deterministic for identical inputs" do
    check all(
            qubits <- integer(3..5),
            state <- normalized_state_generator(qubits),
            terms <- list_of(single_wire_term_generator(qubits), min_length: 24, max_length: 48)
          ) do
      run = fn ->
        state
        |> PauliExpval.expectations(terms, qubits,
          parallel_observables: true,
          parallel_observables_threshold: 1,
          max_concurrency: 4
        )
        |> Enum.map(&Nx.to_number/1)
      end

      assert run.() == run.()
    end
  end

  defp single_wire_term_generator(qubits) do
    map({one_of([constant(:pauli_x), constant(:pauli_y), constant(:pauli_z)]), integer(0..(qubits - 1))}, fn
      {:pauli_x, wire} -> PauliExpval.term_for_observable(:pauli_x, wire)
      {:pauli_y, wire} -> PauliExpval.term_for_observable(:pauli_y, wire)
      {:pauli_z, wire} -> PauliExpval.term_for_observable(:pauli_z, wire)
    end)
  end

  defp normalized_state_generator(qubits) do
    dim = 1 <<< qubits

    map({list_of(float(min: -1.0, max: 1.0), length: dim), list_of(float(min: -1.0, max: 1.0), length: dim)}, fn {real,
                                                                                                                  imag} ->
      norm =
        real
        |> Enum.zip(imag)
        |> Enum.reduce(0.0, fn {r, i}, acc -> acc + r * r + i * i end)
        |> :math.sqrt()
        |> case do
          value when value < 1.0e-9 -> 1.0
          value -> value
        end

      normalized_real = Enum.map(real, &(&1 / norm))
      normalized_imag = Enum.map(imag, &(&1 / norm))

      Nx.complex(
        Nx.tensor(normalized_real, type: {:f, 64}),
        Nx.tensor(normalized_imag, type: {:f, 64})
      )
    end)
  end
end
