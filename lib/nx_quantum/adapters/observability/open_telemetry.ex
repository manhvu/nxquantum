defmodule NxQuantum.Adapters.Observability.OpenTelemetry do
  @moduledoc false

  NxQuantum.Ports.ObservabilityEmitter
  @store_key :nxq_observability_store

  @spec reset() :: :ok
  def reset do
    Process.put(@store_key, %{seq: 0, spans: [], metrics: [], logs: []})
    :ok
  end

  @spec snapshot() :: map()
  def snapshot do
    Map.delete(store(), :seq)
  end

  @spec span_start(String.t(), map(), keyword()) :: map()
  def span_start(name, attributes, _opts) do
    s = next_seq()
    trace_id = "trace-#{s}"
    span_id = "span-#{s}"

    span = %{event: :start, name: name, trace_id: trace_id, span_id: span_id, attributes: attributes}
    append(:spans, span)

    %{trace_id: trace_id, span_id: span_id}
  end

  @spec span_stop(map(), map(), keyword()) :: :ok
  def span_stop(%{trace_id: trace_id, span_id: span_id}, attributes, _opts) do
    append(:spans, %{event: :stop, trace_id: trace_id, span_id: span_id, attributes: attributes})
    :ok
  end

  @spec metric_emit(String.t(), atom(), String.t(), number(), map(), keyword()) :: :ok
  def metric_emit(name, type, unit, value, labels, _opts) do
    append(:metrics, %{name: name, type: type, unit: unit, value: value, labels: labels})
    :ok
  end

  @spec log_emit(map(), keyword()) :: :ok
  def log_emit(entry, _opts) do
    append(:logs, entry)
    :ok
  end

  defp store do
    Process.get(@store_key) || %{seq: 0, spans: [], metrics: [], logs: []}
  end

  defp next_seq do
    current = store()
    updated = current.seq + 1
    Process.put(@store_key, %{current | seq: updated})
    updated
  end

  defp append(key, value) do
    current = store()
    Process.put(@store_key, Map.update!(current, key, &(&1 ++ [value])))
  end
end
