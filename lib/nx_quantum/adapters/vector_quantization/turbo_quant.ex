defmodule NxQuantum.Adapters.VectorQuantization.TurboQuant do
  @moduledoc """
  Deterministic TurboQuant-inspired vector quantization adapter.

  This adapter is intentionally data-oblivious:
  - deterministic signed-permutation rotation from fixed seed,
  - fixed uniform scalar codebooks per bit width,
  - optional residual sign correction for inner-product mode.
  """

  @behaviour NxQuantum.Ports.VectorQuantizer

  import Bitwise

  @default_seed 20_260_328
  @default_mode :mse
  @min_bit_width 2
  @max_bit_width 5

  @impl true
  def quantize_batch(vectors, opts \\ []) when is_list(vectors) do
    with {:ok, dim} <- validate_vectors(vectors),
         {:ok, mode} <- validate_mode(Keyword.get(opts, :mode, @default_mode)),
         {:ok, bit_width} <- validate_bit_width(Keyword.get(opts, :bit_width, 3)),
         {:ok, seed} <- validate_seed(Keyword.get(opts, :seed, @default_seed)) do
      rotation = rotation_plan(dim, seed)
      mse_bit_width = if mode == :prod_unbiased, do: max(@min_bit_width, bit_width - 1), else: bit_width

      entries =
        Enum.map(vectors, fn vector ->
          normalized = normalize(vector)
          rotated = rotate(normalized, rotation)
          idx = quantize_indices(rotated, mse_bit_width)

          if mode == :prod_unbiased do
            reconstructed = dequantize_indices(idx, mse_bit_width)
            residual = residual(rotated, reconstructed)
            residual_norm = l2_norm(residual)

            %{
              idx: idx,
              qjl_sign: Enum.map(residual, &sign_bit/1),
              residual_norm: residual_norm
            }
          else
            %{idx: idx}
          end
        end)

      {:ok,
       %{
         codec: :turboquant,
         schema_version: "v1",
         mode: mode,
         bit_width: bit_width,
         mse_bit_width: mse_bit_width,
         dim: dim,
         seed: seed,
         rotation: rotation,
         entries: entries
       }}
    end
  end

  @impl true
  def estimate_dot_products(query, quantized_batch, opts \\ [])

  def estimate_dot_products(query, %{codec: :turboquant} = quantized_batch, opts) when is_list(query) do
    with {:ok, query_dim} <- validate_vector(query),
         :ok <- ensure_dim(query_dim, quantized_batch.dim) do
      query_rotated = query |> normalize() |> rotate(quantized_batch.rotation)
      strategy = Keyword.get(opts, :parallel_strategy, %{mode: :scalar, max_concurrency: 1, chunk_size: 1})

      scores = score_entries(quantized_batch.entries, query_rotated, quantized_batch, strategy)

      {:ok, scores}
    else
      {:error, _} = error -> error
    end
  end

  def estimate_dot_products(_query, _quantized_batch, _opts) do
    {:error, %{code: :vector_quantizer_invalid_input, field: :quantized_batch}}
  end

  @impl true
  def dequantize_batch(%{codec: :turboquant} = quantized_batch, _opts) do
    vectors =
      Enum.map(quantized_batch.entries, fn entry ->
        base = dequantize_indices(entry.idx, quantized_batch.mse_bit_width)
        repaired = repair_with_residual(base, entry, quantized_batch.dim, quantized_batch.mode)
        unrotate(repaired, quantized_batch.rotation)
      end)

    {:ok, vectors}
  end

  def dequantize_batch(_quantized_batch, _opts) do
    {:error, %{code: :vector_quantizer_invalid_input, field: :quantized_batch}}
  end

  @impl true
  def capabilities(_opts) do
    %{
      codec: :turboquant,
      deterministic: true,
      supported_modes: [:mse, :prod_unbiased],
      bit_width_range: {@min_bit_width, @max_bit_width}
    }
  end

  defp score_entries(entries, query_rotated, quantized_batch, %{mode: :parallel} = strategy) do
    entries
    |> Enum.chunk_every(strategy.chunk_size)
    |> Task.async_stream(
      fn chunk ->
        Enum.map(chunk, &score_entry(query_rotated, quantized_batch, &1))
      end,
      max_concurrency: strategy.max_concurrency,
      ordered: true,
      timeout: :infinity
    )
    |> Enum.flat_map(fn
      {:ok, scores} -> scores
      {:exit, reason} -> raise "turboquant parallel scorer failed: #{inspect(reason)}"
    end)
  end

  defp score_entries(entries, query_rotated, quantized_batch, _strategy) do
    Enum.map(entries, &score_entry(query_rotated, quantized_batch, &1))
  end

  defp score_entry(query_rotated, quantized_batch, entry) do
    base = dequantize_indices(entry.idx, quantized_batch.mse_bit_width)
    mse_component = dot(query_rotated, base)

    if quantized_batch.mode == :prod_unbiased do
      correction_component =
        correction_score(query_rotated, entry.qjl_sign, entry.residual_norm, quantized_batch.dim)

      mse_component + correction_component
    else
      mse_component
    end
  end

  defp correction_score(_query_rotated, _qjl_sign, residual_norm, _dim) when residual_norm == 0.0, do: 0.0

  defp correction_score(query_rotated, qjl_sign, residual_norm, dim) do
    residual_norm / :math.sqrt(max(1, dim)) * dot(query_rotated, qjl_sign)
  end

  defp repair_with_residual(base, %{qjl_sign: qjl_sign, residual_norm: residual_norm}, dim, :prod_unbiased) do
    scale = residual_norm / :math.sqrt(max(1, dim))
    Enum.zip_with(base, qjl_sign, fn v, s -> v + scale * s end)
  end

  defp repair_with_residual(base, _entry, _dim, _mode), do: base

  defp validate_vectors([]), do: {:error, %{code: :vector_quantizer_invalid_input, field: :vectors}}

  defp validate_vectors(vectors) do
    with {:ok, dim} <- validate_vector(hd(vectors)),
         true <- Enum.all?(vectors, fn vector -> is_list(vector) and length(vector) == dim end) do
      {:ok, dim}
    else
      false -> {:error, %{code: :vector_quantizer_dimension_mismatch, field: :vectors}}
      {:error, _} = error -> error
    end
  end

  defp validate_vector(vector) when is_list(vector) do
    if vector != [] and Enum.all?(vector, &is_number/1) do
      {:ok, length(vector)}
    else
      {:error, %{code: :vector_quantizer_invalid_input, field: :vector}}
    end
  end

  defp validate_vector(_), do: {:error, %{code: :vector_quantizer_invalid_input, field: :vector}}

  defp validate_mode(mode) when mode in [:mse, :prod_unbiased], do: {:ok, mode}
  defp validate_mode(_), do: {:error, %{code: :vector_quantizer_unsupported_mode, field: :mode}}

  defp validate_bit_width(value) when is_integer(value) and value >= @min_bit_width and value <= @max_bit_width,
    do: {:ok, value}

  defp validate_bit_width(_), do: {:error, %{code: :vector_quantizer_invalid_input, field: :bit_width}}

  defp validate_seed(value) when is_integer(value), do: {:ok, value}
  defp validate_seed(_), do: {:error, %{code: :vector_quantizer_invalid_input, field: :seed}}

  defp ensure_dim(dim, dim), do: :ok
  defp ensure_dim(_actual, _expected), do: {:error, %{code: :vector_quantizer_dimension_mismatch, field: :query}}

  defp normalize(vector) do
    norm = l2_norm(vector)

    if norm == 0.0 do
      vector
    else
      Enum.map(vector, &(&1 / norm))
    end
  end

  defp residual(a, b), do: Enum.zip_with(a, b, &(&1 - &2))

  defp l2_norm(vector) do
    vector
    |> Enum.reduce(0.0, fn value, acc -> acc + value * value end)
    |> :math.sqrt()
  end

  defp dot(a, b) do
    a
    |> Enum.zip_with(b, fn x, y -> x * y end)
    |> Enum.sum()
  end

  defp sign_bit(value) when value >= 0, do: 1.0
  defp sign_bit(_value), do: -1.0

  defp quantize_indices(vector, bit_width) do
    levels = 1 <<< bit_width
    step = 2.0 / levels

    Enum.map(vector, fn value ->
      clipped = clamp(value, -1.0, 1.0)
      idx = trunc(Float.floor((clipped + 1.0) / step))
      min(idx, levels - 1)
    end)
  end

  defp dequantize_indices(indices, bit_width) do
    levels = 1 <<< bit_width
    step = 2.0 / levels

    Enum.map(indices, fn idx ->
      -1.0 + (idx + 0.5) * step
    end)
  end

  defp clamp(value, low, _high) when value < low, do: low
  defp clamp(value, _low, high) when value > high, do: high
  defp clamp(value, _low, _high), do: value

  defp rotate(vector, %{perm: perm, signs: signs}) do
    Enum.zip_with(perm, signs, fn idx, sign -> sign * Enum.at(vector, idx) end)
  end

  defp unrotate(rotated, %{perm: perm, signs: signs}) do
    dim = length(perm)

    Enum.reduce(0..(dim - 1), List.duplicate(0.0, dim), fn i, acc ->
      target_idx = Enum.at(perm, i)
      value = Enum.at(signs, i) * Enum.at(rotated, i)
      List.replace_at(acc, target_idx, value)
    end)
  end

  defp rotation_plan(dim, seed) do
    {perm, state_after_perm} = fisher_yates(dim, seeded_state(seed))
    {signs, _state_after_signs} = random_signs(dim, state_after_perm)
    %{perm: perm, signs: signs}
  end

  defp seeded_state(seed) do
    a = rem(abs(seed) + 1, 30_000)
    b = rem(abs(seed * 3) + 7, 30_000)
    c = rem(abs(seed * 5) + 11, 30_000)
    :rand.seed_s(:exsplus, {max(1, a), max(1, b), max(1, c)})
  end

  defp fisher_yates(dim, state) do
    perm = Enum.to_list(0..(dim - 1))

    {perm, state} =
      Enum.reduce(Range.new(dim - 1, 1, -1), {perm, state}, fn i, {acc, st} ->
        {j_float, next_state} = :rand.uniform_s(st)
        j = trunc(Float.floor(j_float * (i + 1)))
        swapped = swap(acc, i, j)
        {swapped, next_state}
      end)

    {perm, state}
  end

  defp random_signs(dim, state) do
    1..dim
    |> Enum.reduce({[], state}, fn _, {acc, st} ->
      {value, next_state} = :rand.uniform_s(st)
      sign = if value < 0.5, do: -1.0, else: 1.0
      {[sign | acc], next_state}
    end)
    |> then(fn {list, st} -> {Enum.reverse(list), st} end)
  end

  defp swap(list, i, j) do
    vi = Enum.at(list, i)
    vj = Enum.at(list, j)
    list |> List.replace_at(i, vj) |> List.replace_at(j, vi)
  end
end
