defmodule NxQuantum.Observables.SparsePauliTest do
  use ExUnit.Case, async: true

  alias NxQuantum.Adapters.Simulators.StateVector.MatrixLibrary
  alias NxQuantum.Observables.SparsePauli

  test "new/2 compresses duplicate terms" do
    {:ok, sparse} =
      SparsePauli.new(3, [
        %{x_mask: 0, z_mask: 1, coeff: 1.0},
        %{x_mask: 0, z_mask: 1, coeff: 2.0},
        %{x_mask: 2, z_mask: 0, coeff: {0.5, 0.0}}
      ])

    assert length(sparse.terms) == 2

    term = Enum.find(sparse.terms, fn candidate -> candidate.x_mask == 0 and candidate.z_mask == 1 end)

    assert term.x_mask == 0
    assert term.z_mask == 1
    assert_in_delta elem(term.coeff, 0), 3.0, 1.0e-12
    assert_in_delta elem(term.coeff, 1), 0.0, 1.0e-12
  end

  test "to_dense/2 matches reference Pauli-Z matrix" do
    {:ok, sparse} = SparsePauli.from_observable_specs(1, [%{observable: :pauli_z, wire: 0}])
    dense = SparsePauli.to_dense(sparse)
    reference = MatrixLibrary.observable_matrix(:pauli_z, 0, 1)

    max_diff =
      dense
      |> Nx.subtract(reference)
      |> Nx.abs()
      |> Nx.reduce_max()
      |> Nx.to_number()

    assert max_diff < 1.0e-12
  end

  test "to_csr/2 reconstructs the same dense matrix" do
    {:ok, sparse} =
      SparsePauli.new(2, [
        %{observable: :pauli_x, wire: 0, coeff: 1.0},
        %{observable: :pauli_z, wire: 1, coeff: 0.5}
      ])

    dense = SparsePauli.to_dense(sparse)
    csr = SparsePauli.to_csr(sparse)
    reconstructed = csr_to_dense(csr)

    max_diff =
      dense
      |> Nx.subtract(reconstructed)
      |> Nx.abs()
      |> Nx.reduce_max()
      |> Nx.to_number()

    assert max_diff < 1.0e-12
  end

  test "parallel dense generation matches sequential generation" do
    terms =
      Enum.map(0..15, fn mask ->
        %{x_mask: 0, z_mask: mask, coeff: 1.0}
      end)

    {:ok, sparse} = SparsePauli.new(4, terms)

    sequential = SparsePauli.to_dense(sparse, parallel: false)
    parallel = SparsePauli.to_dense(sparse, parallel: true, parallel_threshold: 2, max_concurrency: 4)

    max_diff =
      sequential
      |> Nx.subtract(parallel)
      |> Nx.abs()
      |> Nx.reduce_max()
      |> Nx.to_number()

    assert max_diff < 1.0e-12
  end

  defp csr_to_dense(%{indptr: indptr_t, indices: indices_t, data: data_t, shape: {rows, cols}}) do
    indptr = Nx.to_flat_list(indptr_t)
    indices = Nx.to_flat_list(indices_t)
    data = Nx.to_flat_list(data_t)

    entry_map =
      Enum.reduce(0..(rows - 1), %{}, fn row, acc ->
        start_idx = Enum.at(indptr, row)
        end_idx = Enum.at(indptr, row + 1)

        if end_idx > start_idx do
          row_entries =
            Enum.map(start_idx..(end_idx - 1), fn idx ->
              {row, Enum.at(indices, idx), complex_tuple(Enum.at(data, idx))}
            end)

          Enum.reduce(row_entries, acc, fn {r, c, coeff}, inner -> Map.put(inner, {r, c}, coeff) end)
        else
          acc
        end
      end)

    real_rows =
      for row <- 0..(rows - 1) do
        for col <- 0..(cols - 1) do
          entry_map
          |> Map.get({row, col}, {0.0, 0.0})
          |> elem(0)
        end
      end

    imag_rows =
      for row <- 0..(rows - 1) do
        for col <- 0..(cols - 1) do
          entry_map
          |> Map.get({row, col}, {0.0, 0.0})
          |> elem(1)
        end
      end

    Nx.complex(Nx.tensor(real_rows, type: {:f, 64}), Nx.tensor(imag_rows, type: {:f, 64}))
  end

  defp complex_tuple(%Complex{re: real, im: imag}), do: {real * 1.0, imag * 1.0}
  defp complex_tuple({real, imag}) when is_number(real) and is_number(imag), do: {real * 1.0, imag * 1.0}
  defp complex_tuple(value) when is_number(value), do: {value * 1.0, 0.0}
end
