defmodule NxQuantum.Adapters.VectorQuantization.TurboQuantTest do
  use ExUnit.Case, async: true

  alias NxQuantum.Adapters.VectorQuantization.TurboQuant

  test "quantize_batch and estimate_dot_products are deterministic for fixed seed" do
    vectors = [
      [0.2, -0.5, 0.7, 0.1],
      [0.1, 0.3, -0.2, 0.4],
      [-0.7, 0.4, 0.2, -0.1]
    ]

    opts = [mode: :mse, bit_width: 3, seed: 123]
    query = [0.6, -0.1, 0.2, 0.9]

    assert {:ok, batch_a} = TurboQuant.quantize_batch(vectors, opts)
    assert {:ok, batch_b} = TurboQuant.quantize_batch(vectors, opts)
    assert batch_a == batch_b

    assert {:ok, scores_a} = TurboQuant.estimate_dot_products(query, batch_a)
    assert {:ok, scores_b} = TurboQuant.estimate_dot_products(query, batch_b)
    assert scores_a == scores_b
    assert length(scores_a) == 3
  end

  test "prod_unbiased mode supports deterministic parallel scoring" do
    vectors =
      Enum.map(1..48, fn i ->
        Enum.map(1..32, fn j -> :math.sin((i + j) / 11.0) end)
      end)

    query = Enum.map(1..32, fn i -> :math.cos(i / 9.0) end)
    opts = [mode: :prod_unbiased, bit_width: 4, seed: 2026]

    assert {:ok, batch} = TurboQuant.quantize_batch(vectors, opts)

    scalar = %{mode: :scalar, max_concurrency: 1, chunk_size: 48}
    parallel = %{mode: :parallel, max_concurrency: 4, chunk_size: 6}

    assert {:ok, scalar_scores} = TurboQuant.estimate_dot_products(query, batch, parallel_strategy: scalar)
    assert {:ok, parallel_scores} = TurboQuant.estimate_dot_products(query, batch, parallel_strategy: parallel)
    assert scalar_scores == parallel_scores
  end

  test "dimension mismatch returns typed error" do
    assert {:ok, batch} = TurboQuant.quantize_batch([[0.1, 0.2], [0.3, 0.4]], mode: :mse, bit_width: 3, seed: 1)
    assert {:error, error} = TurboQuant.estimate_dot_products([0.2, 0.3, 0.4], batch)
    assert error.code == :vector_quantizer_dimension_mismatch
  end
end
