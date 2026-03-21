defmodule NxQuantum.Observability.ProfileStrategy.Granular do
  @moduledoc false

  @behaviour NxQuantum.Observability.ProfileStrategy

  alias NxQuantum.Observability.ProfileStrategy.HighLevel

  @impl true
  def emit_metrics(adapter, operation, labels, status, opts) do
    HighLevel.emit_metrics(adapter, operation, labels, status, opts)

    if operation == :poll do
      adapter.metric_emit("nxq.provider.queue_wait_ms", :histogram, "ms", 0.5, labels, opts)
      adapter.metric_emit("nxq.provider.execution_ms", :histogram, "ms", 0.5, labels, opts)
    end

    :ok
  end
end
