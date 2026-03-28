defmodule NxQuantum.AI.Tools.KernelRerank.ExecutionStrategy do
  @moduledoc false

  @default_parallel_threshold 32
  @default_parallel_min_work 16_384

  @type t :: %{
          mode: :scalar | :parallel,
          max_concurrency: pos_integer(),
          chunk_size: pos_integer()
        }

  @spec select(non_neg_integer(), non_neg_integer(), keyword()) :: t()
  def select(candidate_count, dim, opts) do
    parallel_mode = Keyword.get(opts, :parallel_mode, :auto)
    parallel? = Keyword.get(opts, :parallel, true)
    threshold = Keyword.get(opts, :parallel_threshold, @default_parallel_threshold)
    min_work = Keyword.get(opts, :parallel_min_work, @default_parallel_min_work)
    max_concurrency = max_concurrency(opts)

    estimated_work = max(1, candidate_count) * max(1, dim)
    parallel_eligible? = parallel? and candidate_count >= threshold and estimated_work >= min_work

    case parallel_mode do
      :force_scalar ->
        scalar_strategy(candidate_count)

      :force_parallel ->
        parallel_strategy(candidate_count, max_concurrency)

      :auto ->
        if(parallel_eligible?,
          do: parallel_strategy(candidate_count, max_concurrency),
          else: scalar_strategy(candidate_count)
        )

      _unsupported ->
        scalar_strategy(candidate_count)
    end
  end

  defp parallel_strategy(candidate_count, max_concurrency) do
    chunk_size = (candidate_count + max_concurrency - 1) |> div(max_concurrency * 2) |> max(1)
    %{mode: :parallel, max_concurrency: max_concurrency, chunk_size: chunk_size}
  end

  defp scalar_strategy(candidate_count), do: %{mode: :scalar, max_concurrency: 1, chunk_size: max(1, candidate_count)}

  defp max_concurrency(opts) do
    opts
    |> Keyword.get(:max_concurrency, System.schedulers_online())
    |> case do
      value when is_integer(value) and value > 0 -> value
      _ -> System.schedulers_online()
    end
  end
end
