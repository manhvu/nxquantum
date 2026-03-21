defmodule NxQuantum.Adapters.Observability.Noop do
  @moduledoc false

  @spec reset() :: :ok
  def reset, do: :ok

  @spec snapshot() :: map()
  def snapshot, do: %{spans: [], metrics: [], logs: []}

  @spec span_start(String.t(), map(), keyword()) :: map()
  def span_start(_name, _attributes, _opts), do: %{trace_id: nil, span_id: nil}

  @spec span_stop(map(), map(), keyword()) :: :ok
  def span_stop(_span_ctx, _attributes, _opts), do: :ok

  @spec metric_emit(String.t(), atom(), String.t(), number(), map(), keyword()) :: :ok
  def metric_emit(_name, _type, _unit, _value, _labels, _opts), do: :ok

  @spec log_emit(map(), keyword()) :: :ok
  def log_emit(_entry, _opts), do: :ok
end
