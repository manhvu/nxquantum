defmodule NxQuantum.Sampler.Batch.Strategy do
  @moduledoc false

  @callback run([term()], keyword(), (term() -> term())) :: [term()]
end
