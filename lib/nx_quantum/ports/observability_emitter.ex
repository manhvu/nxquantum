defmodule NxQuantum.Ports.ObservabilityEmitter do
  @moduledoc """
  Port for emitting observability signals (traces, metrics and logs).
  """

  @callback reset() :: :ok
  @callback snapshot() :: map()
  @callback span_start(String.t(), map(), keyword()) :: map()
  @callback span_stop(map(), map(), keyword()) :: :ok
  @callback metric_emit(String.t(), atom(), String.t(), number(), map(), keyword()) :: :ok
  @callback log_emit(map(), keyword()) :: :ok
end
