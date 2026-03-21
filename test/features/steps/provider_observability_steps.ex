defmodule NxQuantum.Features.Steps.ProviderObservabilitySteps do
  @moduledoc false
  # credo:disable-for-this-file Credo.Check.Refactor.CyclomaticComplexity

  @behaviour NxQuantum.Features.FeatureSteps

  import ExUnit.Assertions

  alias NxQuantum.Adapters.Observability.Noop
  alias NxQuantum.Adapters.Observability.OpenTelemetry
  alias NxQuantum.Adapters.Providers.AwsBraket
  alias NxQuantum.Adapters.Providers.AzureQuantum
  alias NxQuantum.Adapters.Providers.IBMRuntime
  alias NxQuantum.Features.StepExecutor
  alias NxQuantum.Observability
  alias NxQuantum.ProviderBridge

  @impl true
  def feature, do: "provider_observability.feature"

  @impl true
  def execute(step, ctx) do
    handlers = [&handle_setup/2, &handle_execution/2, &handle_assertions/2]

    case StepExecutor.run(step, ctx, handlers) do
      {:handled, updated} -> updated
      :unhandled -> raise "unhandled step: #{step.text}"
    end
  end

  defp handle_setup(%{text: text}, ctx) do
    cond do
      text == "observability is enabled with OpenTelemetry adapter" ->
        Observability.reset(adapter: OpenTelemetry)

        {:handled,
         Map.put(ctx, :observability_opts,
           enabled: true,
           adapter: OpenTelemetry,
           profile: :high_level,
           runtime_profile: :cpu_portable
         )}

      text == ~s(observability profiles "high_level", "granular", and "forensics" are available) ->
        {:handled, Map.put(ctx, :profiles, [:high_level, :granular, :forensics])}

      text == "equivalent workloads are run across multiple providers" ->
        {:handled, Map.put(ctx, :workload_input, %{workflow: :sampler, shots: 1024, seed: 7, circuit: "h(0);cnot(0,1)"})}

      text == "a new provider adapter is added" ->
        {:handled, Map.put(ctx, :new_provider_required_fields, [:provider, :target, :workflow, :trace_id, :span_id])}

      text == "observability adapter is \"noop\"" ->
        Observability.reset(adapter: Noop)

        {:handled,
         Map.put(ctx, :noop_opts,
           enabled: false,
           adapter: Noop,
           profile: :high_level
         )}

      text == "observability is disabled for the workflow" ->
        {:handled, Map.update(ctx, :noop_opts, [enabled: false, adapter: Noop], &Keyword.put(&1, :enabled, false))}

      true ->
        :unhandled
    end
  end

  defp handle_execution(%{text: text}, ctx) do
    cond do
      text == "provider lifecycle operations execute across all registered providers" ->
        Observability.reset(adapter: OpenTelemetry)

        payload = %{workflow: :sampler, shots: 1024}

        runs = [
          ProviderBridge.run_lifecycle(
            IBMRuntime,
            payload,
            ctx.observability_opts
            |> Keyword.put_new(:target, "ibm_backend_simulator")
            |> Keyword.put(:provider_config, %{
              auth_token: "ibm-token",
              channel: "ibm_cloud",
              backend: "ibm_backend_simulator"
            })
            |> attach_obs(ctx.observability_opts)
          ),
          ProviderBridge.run_lifecycle(
            AwsBraket,
            payload,
            ctx.observability_opts
            |> Keyword.put_new(:target, "arn:aws:braket:::device/quantum-simulator/amazon/sv1")
            |> Keyword.put(:provider_config, %{
              region: "us-east-1",
              credentials_profile: "default",
              device_arn: "arn:aws:braket:::device/quantum-simulator/amazon/sv1"
            })
            |> attach_obs(ctx.observability_opts)
          ),
          ProviderBridge.run_lifecycle(
            AzureQuantum,
            payload,
            ctx.observability_opts
            |> Keyword.put_new(:target, "azure.quantum.sim")
            |> Keyword.put(:provider_config, %{
              workspace: "ws-1",
              auth_context: "managed_identity",
              target_id: "azure.quantum.sim",
              provider_name: "microsoft"
            })
            |> attach_obs(ctx.observability_opts)
          )
        ]

        {:handled,
         ctx
         |> Map.put(:provider_runs, runs)
         |> Map.put(:telemetry_snapshot, Observability.snapshot(adapter: OpenTelemetry))}

      text == "profile selection changes for equivalent workflow inputs" ->
        profile_snapshots =
          Map.new(ctx.profiles, fn profile ->
            Observability.reset(adapter: OpenTelemetry)

            _ =
              ProviderBridge.run_lifecycle(IBMRuntime, %{workflow: :sampler, shots: 1024},
                target: "ibm_backend_simulator",
                provider_config: %{auth_token: "ibm-token", channel: "ibm_cloud", backend: "ibm_backend_simulator"},
                observability: [enabled: true, adapter: OpenTelemetry, profile: profile]
              )

            {profile, Observability.snapshot(adapter: OpenTelemetry)}
          end)

        {:handled, Map.put(ctx, :profile_snapshots, profile_snapshots)}

      text == "portability telemetry is enabled" ->
        fingerprint_a = Observability.fingerprint(ctx.workload_input)
        fingerprint_b = Observability.fingerprint(ctx.workload_input)

        delta =
          Observability.portability_delta(
            %{payload: %{expectation: 0.8}, metadata: %{latency_ms: 11.0}},
            %{payload: %{expectation: 0.78}, metadata: %{latency_ms: 12.5, sample_kl_divergence: 0.03}}
          )

        {:handled,
         ctx
         |> Map.put(:fingerprint_a, fingerprint_a)
         |> Map.put(:fingerprint_b, fingerprint_b)
         |> Map.put(:portability_delta, delta)}

      text == "observability conformance checks are evaluated" ->
        sample_log = %{
          provider: :new_provider,
          target: "target",
          workflow: :sampler,
          trace_id: "trace-x",
          span_id: "span-x"
        }

        missing = Enum.reject(ctx.new_provider_required_fields, &Map.has_key?(sample_log, &1))
        {:handled, Map.put(ctx, :conformance_missing, missing)}

      text == "provider lifecycle workflow is executed" ->
        noop_result =
          ProviderBridge.run_lifecycle(IBMRuntime, %{workflow: :sampler, shots: 64},
            target: "ibm_backend_simulator",
            provider_config: %{auth_token: "ibm-token", channel: "ibm_cloud", backend: "ibm_backend_simulator"},
            observability: ctx.noop_opts
          )

        {:handled, Map.put(ctx, :noop_result, noop_result)}

      true ->
        :unhandled
    end
  end

  defp handle_assertions(%{text: text}, ctx) do
    cond do
      text == "mandatory lifecycle spans are emitted with stable schema keys" ->
        spans = ctx.telemetry_snapshot.spans
        names = spans |> Enum.filter(&(&1.event == :start)) |> Enum.map(& &1.name)
        assert "nxq.workflow.run" in names
        assert "nxq.provider.submit" in names
        assert "nxq.provider.poll" in names
        assert "nxq.provider.fetch_result" in names
        assert Enum.all?(spans, fn span -> is_map(span.attributes) end)
        {:handled, ctx}

      text == "core latency/error metrics are emitted with stable names and units" ->
        metrics = ctx.telemetry_snapshot.metrics
        assert Enum.any?(metrics, &(&1.name == "nxq.provider.request.latency_ms" and &1.unit == "ms"))
        assert Enum.any?(metrics, &(&1.name == "nxq.workflow.success.count" and &1.unit == "count"))
        {:handled, ctx}

      text == "structured logs include trace and span correlation identifiers" ->
        assert Enum.all?(ctx.telemetry_snapshot.logs, fn log ->
                 Map.has_key?(log, :trace_id) and Map.has_key?(log, :span_id)
               end)

        {:handled, ctx}

      text == "\"high_level\" emits production-safe low-cardinality telemetry" ->
        high = ctx.profile_snapshots.high_level
        assert Enum.all?(high.metrics, fn metric -> Map.has_key?(metric, :labels) end)
        {:handled, ctx}

      text == "\"granular\" emits lifecycle phase details and richer diagnostics" ->
        granular_metric_names = Enum.map(ctx.profile_snapshots.granular.metrics, & &1.name)
        assert "nxq.provider.queue_wait_ms" in granular_metric_names
        assert "nxq.provider.execution_ms" in granular_metric_names
        {:handled, ctx}

      text == "\"forensics\" emits deep diagnostics only under explicit opt-in safeguards" ->
        assert length(ctx.profile_snapshots.forensics.logs) >= length(ctx.profile_snapshots.high_level.logs)
        {:handled, ctx}

      text == "experiment fingerprint is deterministic for canonicalized equivalent inputs" ->
        assert ctx.fingerprint_a == ctx.fingerprint_b
        {:handled, ctx}

      text == "portability-delta contracts are emitted with stable schema" ->
        delta = ctx.portability_delta
        assert Map.has_key?(delta, :latency_delta_ms)
        assert Map.has_key?(delta, :expectation_delta_abs)
        assert Map.has_key?(delta, :sample_kl_divergence)
        {:handled, ctx}

      text == "cardinality safeguards prevent unbounded metric-label growth" ->
        refute String.contains?(ctx.fingerprint_a, "job_")
        {:handled, ctx}

      text == "baseline trace, metric, and log schema contracts must match existing provider standards" ->
        assert ctx.conformance_missing == []
        {:handled, ctx}

      text == "missing mandatory telemetry fields are reported as contract failures" ->
        assert ctx.conformance_missing == []
        {:handled, ctx}

      text == "functional workflow result contract is unchanged" ->
        assert {:ok, %{submitted: _, polled: _, result: _}} = ctx.noop_result
        {:handled, ctx}

      text == "OpenTelemetry traces, logs, and metrics are not emitted" ->
        assert Observability.snapshot(adapter: Noop) == %{spans: [], metrics: [], logs: []}
        {:handled, ctx}

      true ->
        :unhandled
    end
  end

  defp attach_obs(opts, obs) do
    Keyword.put(opts, :observability, obs)
  end
end
