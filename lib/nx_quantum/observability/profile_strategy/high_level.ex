defmodule NxQuantum.Observability.ProfileStrategy.HighLevel do
  @moduledoc false

  @behaviour NxQuantum.Observability.ProfileStrategy

  @impl true
  def emit_metrics(adapter, _operation, labels, status, opts) do
    adapter.metric_emit("nxq.provider.request.latency_ms", :histogram, "ms", 1.0, labels, opts)

    counter_name = if status == :ok, do: "nxq.workflow.success.count", else: "nxq.workflow.failure.count"
    adapter.metric_emit(counter_name, :counter, "count", 1, labels, opts)

    if status == :error do
      adapter.metric_emit("nxq.provider.error.count", :counter, "count", 1, labels, opts)
    end

    :ok
  end
end
