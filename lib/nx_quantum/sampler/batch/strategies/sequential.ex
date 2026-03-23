defmodule NxQuantum.Sampler.Batch.Strategies.Sequential do
  @moduledoc false

  @behaviour NxQuantum.Sampler.Batch.Strategy

  @impl true
  @spec run([term()], keyword(), (term() -> term())) :: [term()]
  def run(values, _opts, fun) when is_list(values) and is_function(fun, 1) do
    Enum.map(values, fun)
  end
end
