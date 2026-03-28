defmodule NxQuantum.AI.Tools.KernelRerank do
  @moduledoc false

  alias NxQuantum.Adapters.VectorQuantization.TurboQuant
  alias NxQuantum.AI.Request
  alias NxQuantum.AI.Result
  alias NxQuantum.AI.Tools.KernelRerank.ExecutionStrategy

  @spec run(Request.t(), keyword()) :: {:ok, Result.t()} | {:error, map()}
  def run(%Request{} = request, opts) do
    capabilities = Keyword.get(opts, :provider_capabilities, %{})
    fallback_policy = request.execution_policy[:fallback_policy] || :allow_classical_fallback

    cond do
      Map.get(capabilities, :supports_kernel_rerank, true) ->
        run_quantum_path(request, capabilities, fallback_policy, opts)

      fallback_policy == :allow_classical_fallback ->
        {:ok, fallback_result(request, :provider_capability_unavailable)}

      true ->
        {:error,
         typed_error(
           request,
           :ai_tool_fallback_blocked,
           :policy,
           "kernel rerank requires unavailable capability"
         )}
    end
  end

  defp run_quantum_path(%Request{} = request, capabilities, fallback_policy, opts) do
    case ranking_payload(request, opts) do
      {:ok, ranked, ranking_metadata} ->
        {:ok, quantum_result(request, capabilities, ranked, ranking_metadata)}

      {:error, error} ->
        if fallback_policy == :allow_classical_fallback do
          {:ok, fallback_result(request, error.code)}
        else
          {:error,
           typed_error(
             request,
             error.code,
             :validation,
             Map.get(error, :message, "kernel rerank input invalid"),
             Map.drop(error, [:code, :message])
           )}
        end
    end
  end

  defp ranking_payload(%Request{} = request, opts) do
    input = request.input
    candidate_ids = Map.get(input, :candidate_ids, [])
    score_map = Map.get(input, :scores, %{})

    cond do
      candidate_ids == [] ->
        {:error, %{code: :ai_tool_invalid_request, field: :candidate_ids, message: "candidate_ids required"}}

      is_map(score_map) and map_size(score_map) > 0 ->
        ranked = rank_candidates(candidate_ids, score_map)
        {:ok, ranked, %{ranking_mode: :scores}}

      true ->
        ranking_with_embeddings(candidate_ids, input, opts)
    end
  end

  defp ranking_with_embeddings(candidate_ids, input, opts) do
    with {:ok, query} <- fetch_query_embedding(input),
         {:ok, vectors} <- fetch_candidate_vectors(candidate_ids, input),
         {:ok, quantization_opts} <- quantization_opts(input),
         {:ok, dim} <- validate_dim(vectors, query) do
      strategy = ExecutionStrategy.select(length(candidate_ids), dim, quantization_opts)
      quantizer = Keyword.get(opts, :vector_quantizer, TurboQuant)

      with {:ok, quantized} <- quantizer.quantize_batch(vectors, quantization_opts),
           {:ok, scores} <- quantizer.estimate_dot_products(query, quantized, parallel_strategy: strategy) do
        score_map = candidate_ids |> Enum.zip(scores) |> Map.new()
        ranked = rank_candidates(candidate_ids, score_map)

        {:ok, ranked,
         %{
           ranking_mode: :quantized_embeddings,
           quantization_codec: :turboquant,
           quantization_mode: Keyword.get(quantization_opts, :mode, :mse),
           bit_width: Keyword.get(quantization_opts, :bit_width, 3),
           seed: Keyword.get(quantization_opts, :seed, 20_260_328),
           parallel_mode: strategy.mode,
           max_concurrency: strategy.max_concurrency,
           chunk_size: strategy.chunk_size,
           vector_dim: dim
         }}
      end
    end
  end

  defp fetch_query_embedding(input) do
    case Map.get(input, :query_embedding) do
      query when is_list(query) ->
        if query != [] and Enum.all?(query, &is_number/1) do
          {:ok, query}
        else
          {:error,
           %{
             code: :ai_tool_invalid_request,
             field: :query_embedding,
             message: "query_embedding required when scores are not provided"
           }}
        end

      _ ->
        {:error,
         %{
           code: :ai_tool_invalid_request,
           field: :query_embedding,
           message: "query_embedding required when scores are not provided"
         }}
    end
  end

  defp fetch_candidate_vectors(candidate_ids, input) do
    case Map.get(input, :candidate_embeddings) do
      embeddings when is_map(embeddings) ->
        vectors =
          Enum.map(candidate_ids, fn id ->
            Map.get(embeddings, id)
          end)

        if Enum.all?(vectors, fn vec -> is_list(vec) and vec != [] and Enum.all?(vec, &is_number/1) end) do
          {:ok, vectors}
        else
          {:error,
           %{
             code: :ai_tool_invalid_request,
             field: :candidate_embeddings,
             message: "candidate_embeddings must include numeric vectors for all candidate_ids"
           }}
        end

      _ ->
        {:error,
         %{
           code: :ai_tool_invalid_request,
           field: :candidate_embeddings,
           message: "candidate_embeddings required when scores are not provided"
         }}
    end
  end

  defp quantization_opts(input) do
    quantization = Map.get(input, :quantization, %{})
    codec = Map.get(quantization, :codec, :turboquant)

    if codec == :turboquant do
      {:ok,
       [
         mode: Map.get(quantization, :mode, :mse),
         bit_width: Map.get(quantization, :bit_width, 3),
         seed: Map.get(quantization, :seed, 20_260_328),
         parallel_mode: Map.get(quantization, :parallel_mode, :auto),
         parallel: Map.get(quantization, :parallel, true),
         parallel_threshold: Map.get(quantization, :parallel_threshold, 32),
         parallel_min_work: Map.get(quantization, :parallel_min_work, 16_384),
         max_concurrency: Map.get(quantization, :max_concurrency, System.schedulers_online())
       ]}
    else
      {:error,
       %{
         code: :ai_tool_unsupported,
         field: :quantization_codec,
         message: "unsupported quantization codec"
       }}
    end
  end

  defp validate_dim(vectors, query) do
    dim = length(hd(vectors))

    if length(query) == dim and Enum.all?(vectors, fn vec -> length(vec) == dim end) do
      {:ok, dim}
    else
      {:error, %{code: :ai_tool_invalid_request, field: :embedding_dim, message: "embedding dimension mismatch"}}
    end
  end

  defp quantum_result(%Request{} = request, capabilities, ranked, ranking_metadata) do
    Result.ok(%{
      request_id: request.request_id,
      correlation_id: request.correlation_id,
      tool_name: request.tool_name,
      output: %{ranked_candidate_ids: ranked},
      execution: %{
        mode: :quantum,
        provider: Map.get(capabilities, :provider, :none),
        target: Map.get(capabilities, :target, :none)
      },
      metadata: %{ranking: ranking_metadata}
    })
  end

  defp fallback_result(%Request{} = request, reason) do
    candidate_ids = Map.get(request.input, :candidate_ids, [])

    Result.fallback(%{
      request_id: request.request_id,
      correlation_id: request.correlation_id,
      tool_name: request.tool_name,
      output: %{ranked_candidate_ids: Enum.sort(candidate_ids)},
      execution: %{mode: :classical_fallback, provider: :none, target: :none},
      diagnostics: [%{code: :kernel_rerank_fallback, reason: reason}],
      metadata: %{ranking: %{ranking_mode: :fallback_sorted}}
    })
  end

  defp rank_candidates(candidate_ids, score_map) do
    candidate_ids
    |> Enum.map(fn id -> {id, Map.get(score_map, id, 0.0)} end)
    |> Enum.sort_by(fn {id, score} -> {-score, id} end)
    |> Enum.map(&elem(&1, 0))
  end

  defp typed_error(%Request{} = request, code, category, message, details \\ %{}) do
    %{
      schema_version: "v1",
      request_id: request.request_id,
      correlation_id: request.correlation_id,
      code: code,
      category: category,
      retryable: false,
      message: message,
      details: Map.merge(%{tool_name: request.tool_name}, details)
    }
  end
end
