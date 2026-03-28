defmodule NxQuantum.Ports.VectorQuantizer do
  @moduledoc """
  Port contract for deterministic vector quantization used by AI rerank workflows.
  """

  @type vector :: [number()]
  @type quantized_batch :: map()
  @type typed_error :: %{required(:code) => atom(), optional(atom()) => term()}

  @callback quantize_batch([vector()], keyword()) :: {:ok, quantized_batch()} | {:error, typed_error()}
  @callback estimate_dot_products(vector(), quantized_batch(), keyword()) ::
              {:ok, [float()]} | {:error, typed_error()}
  @callback dequantize_batch(quantized_batch(), keyword()) :: {:ok, [vector()]} | {:error, typed_error()}
  @callback capabilities(keyword()) :: map()
end
