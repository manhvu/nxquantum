defmodule NxQuantum.Sampler.Batch.Strategies.Parallel do
  @moduledoc false

  @behaviour NxQuantum.Sampler.Batch.Strategy

  alias NxQuantum.Sampler.ExecutionMode

  @impl true
  @spec run([term()], keyword(), (term() -> term())) :: [term()]
  def run(values, opts, fun) when is_list(values) and is_function(fun, 1) do
    max_concurrency = ExecutionMode.max_concurrency(opts)

    values
    |> Task.async_stream(fun,
      max_concurrency: max_concurrency,
      ordered: true,
      timeout: :infinity
    )
    |> Enum.map(fn
      {:ok, result} -> result
      {:exit, reason} -> {:error, %{code: :batch_parallel_worker_crash, reason: reason}}
    end)
  end
end
