defmodule NxQuantum.Sampler.BatchedRunner do
  @moduledoc false

  alias NxQuantum.Sampler.Batch.Strategies.Parallel
  alias NxQuantum.Sampler.Batch.Strategies.Sequential
  alias NxQuantum.Sampler.ExecutionMode

  @spec run([term()], keyword(), (term() -> term())) :: [term()]
  def run(values, opts, fun) when is_list(values) and is_function(fun, 1) do
    strategy_for(opts).run(values, opts, fun)
  end

  defp strategy_for(opts) do
    case ExecutionMode.classify_batch(opts) do
      :parallel -> Parallel
      :sequential -> Sequential
    end
  end
end
