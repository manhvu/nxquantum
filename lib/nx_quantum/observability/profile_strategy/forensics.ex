defmodule NxQuantum.Observability.ProfileStrategy.Forensics do
  @moduledoc false

  @behaviour NxQuantum.Observability.ProfileStrategy

  alias NxQuantum.Observability.ProfileStrategy.Granular

  @impl true
  def emit_metrics(adapter, operation, labels, status, opts) do
    Granular.emit_metrics(adapter, operation, labels, status, opts)
  end
end
