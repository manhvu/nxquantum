defmodule NxQuantum.KernelsTest do
  use ExUnit.Case, async: true

  alias NxQuantum.Kernels
  alias NxQuantum.TestSupport.Fixtures

  test "kernel matrix is deterministic and symmetric" do
    x =
      Nx.tensor([
        [0.0, 0.0],
        [1.0, 0.2],
        [0.5, -0.8]
      ])

    k1 = Kernels.matrix(x, gamma: 0.5, seed: 1234)
    k2 = Kernels.matrix(x, gamma: 0.5, seed: 1234)

    assert Nx.shape(k1) == {3, 3}
    assert Nx.to_flat_list(k1) == Nx.to_flat_list(k2)
    assert Fixtures.symmetric?(k1, 1.0e-10)
    assert Fixtures.psd_by_quadratic_form?(k1, 1.0e-8)
  end

  test "different seeds yield different kernel matrices for the same dataset" do
    x =
      Nx.tensor([
        [0.0, 0.0],
        [1.0, 0.2],
        [0.5, -0.8]
      ])

    k1 = Kernels.matrix(x, gamma: 0.5, seed: 7)
    k2 = Kernels.matrix(x, gamma: 0.5, seed: 99)

    refute Nx.to_flat_list(k1) == Nx.to_flat_list(k2)
  end

  test "raises for non-2d input tensors" do
    assert_raise ArgumentError, ~r/expected rank-2 tensor/, fn ->
      Kernels.matrix(Nx.tensor([1.0, 2.0, 3.0]))
    end
  end
end
