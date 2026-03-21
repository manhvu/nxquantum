defmodule NxQuantum.Observability do
  @moduledoc """
  Observability helpers for provider lifecycle and cross-provider comparability.
  """

  alias NxQuantum.Observability.Fingerprint
  alias NxQuantum.Observability.PortabilityDelta
  alias NxQuantum.Observability.Profile

  @default_adapter NxQuantum.Adapters.Observability.Noop

  @spec reset(keyword()) :: :ok
  def reset(opts \\ []) do
    adapter(opts).reset()
  end

  @spec snapshot(keyword()) :: map()
  def snapshot(opts \\ []) do
    adapter(opts).snapshot()
  end

  @spec trace_lifecycle(atom(), atom() | String.t(), String.t(), atom(), keyword(), (-> any())) :: any()
  def trace_lifecycle(operation, provider, target, workflow, opts, fun) when is_function(fun, 0) do
    profile = Profile.normalize(Keyword.get(opts, :profile, :high_level))

    if Profile.enabled?(opts) do
      adapter = adapter(opts)
      span_name = "nxq.provider.#{operation}"

      attrs = %{
        nxq_provider: provider,
        nxq_target: target,
        nxq_workflow: workflow,
        nxq_runtime_profile: Keyword.get(opts, :runtime_profile, :cpu_portable),
        nxq_visibility_profile: profile
      }

      span_ctx = adapter.span_start(span_name, attrs, opts)

      result = fun.()
      status = if match?({:ok, _}, result), do: :ok, else: :error

      adapter.span_stop(span_ctx, Map.put(attrs, :status, status), opts)
      emit_standard_metrics(adapter, operation, provider, target, workflow, status, opts)

      adapter.log_emit(
        %{
          event: "nxq.lifecycle.transition",
          level: :info,
          message: "provider lifecycle operation executed",
          provider: provider,
          target: target,
          workflow: workflow,
          trace_id: span_ctx.trace_id,
          span_id: span_ctx.span_id
        },
        opts
      )

      result
    else
      fun.()
    end
  end

  @spec trace_workflow(atom() | String.t(), String.t(), atom(), keyword(), (-> any())) :: any()
  def trace_workflow(provider, target, workflow, opts, fun) when is_function(fun, 0) do
    if Profile.enabled?(opts) do
      adapter = adapter(opts)

      attrs = %{
        nxq_provider: provider,
        nxq_target: target,
        nxq_workflow: workflow,
        nxq_visibility_profile: Profile.normalize(Keyword.get(opts, :profile, :high_level))
      }

      span_ctx = adapter.span_start("nxq.workflow.run", attrs, opts)
      result = fun.()
      status = if match?({:ok, _}, result), do: :ok, else: :error
      adapter.span_stop(span_ctx, Map.put(attrs, :status, status), opts)
      result
    else
      fun.()
    end
  end

  @spec fingerprint(map(), keyword()) :: String.t()
  def fingerprint(input, opts \\ []), do: Fingerprint.generate(input, opts)

  @spec portability_delta(map(), map()) :: map()
  def portability_delta(reference, candidate), do: PortabilityDelta.compute(reference, candidate)

  defp emit_standard_metrics(adapter, operation, provider, target, workflow, status, opts) do
    labels = %{
      provider: provider,
      target: target,
      workflow: workflow,
      visibility_profile: Profile.normalize(Keyword.get(opts, :profile, :high_level))
    }

    adapter.metric_emit("nxq.provider.request.latency_ms", :histogram, "ms", 1.0, labels, opts)

    counter_name = if status == :ok, do: "nxq.workflow.success.count", else: "nxq.workflow.failure.count"
    adapter.metric_emit(counter_name, :counter, "count", 1, labels, opts)

    if operation == :poll and Profile.normalize(Keyword.get(opts, :profile, :high_level)) in [:granular, :forensics] do
      adapter.metric_emit("nxq.provider.queue_wait_ms", :histogram, "ms", 0.5, labels, opts)
      adapter.metric_emit("nxq.provider.execution_ms", :histogram, "ms", 0.5, labels, opts)
    end

    if status == :error do
      adapter.metric_emit("nxq.provider.error.count", :counter, "count", 1, labels, opts)
    end
  end

  defp adapter(opts) do
    Keyword.get(opts, :adapter, @default_adapter)
  end
end
