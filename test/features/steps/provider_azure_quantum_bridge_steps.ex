defmodule NxQuantum.Features.Steps.ProviderAzureQuantumBridgeSteps do
  @moduledoc false
  # credo:disable-for-this-file Credo.Check.Refactor.CyclomaticComplexity

  @behaviour NxQuantum.Features.FeatureSteps

  import ExUnit.Assertions

  alias NxQuantum.Adapters.Providers.AzureQuantum
  alias NxQuantum.Features.StepExecutor
  alias NxQuantum.ProviderBridge

  defmodule BrokenAzurePayloadProvider do
    @moduledoc false

    @behaviour NxQuantum.Ports.Provider

    @impl true
    def provider_id, do: :azure_quantum

    @impl true
    def capabilities(_target, _opts) do
      {:ok,
       %{
         supports_estimator: true,
         supports_sampler: true,
         supports_batch: true,
         supports_dynamic: false,
         supports_cancel_in_running: true,
         supports_calibration_payload: true,
         target_class: :gate_model
       }}
    end

    @impl true
    def submit(_payload, _opts), do: :unexpected

    @impl true
    def poll(job, _opts), do: {:ok, job}

    @impl true
    def cancel(job, _opts), do: {:ok, job}

    @impl true
    def fetch_result(_job, _opts), do: {:ok, %{}}
  end

  @impl true
  def feature, do: "provider_azure_quantum_bridge.feature"

  @impl true
  def execute(step, ctx) do
    handlers = [&handle_setup/2, &handle_execution/2, &handle_assertions/2, &handle_errors/2]

    case StepExecutor.run(step, ctx, handlers) do
      {:handled, updated} -> updated
      :unhandled -> raise "unhandled step: #{step.text}"
    end
  end

  defp handle_setup(%{text: text}, ctx) do
    cond do
      text == "Azure Quantum integration is configured with workspace and target/provider selectors" ->
        {:handled,
         Map.merge(ctx, %{
           provider: AzureQuantum,
           payload: %{workflow: :sampler, shots: 1024},
           opts: [
             target: "azure.quantum.sim",
             provider_config: %{
               workspace: "ws-1",
               auth_context: "managed_identity",
               target_id: "azure.quantum.sim",
               provider_name: "microsoft"
             }
           ]
         })}

      text == "Azure Quantum provider lifecycle operations are requested" ->
        {:handled,
         Map.merge(ctx, %{
           provider: AzureQuantum,
           payload: %{workflow: :sampler, shots: 1024},
           opts: [
             target: "azure.quantum.sim",
             provider_config: %{
               workspace: "ws-1",
               auth_context: "managed_identity",
               target_id: "azure.quantum.sim",
               provider_name: "microsoft"
             }
           ]
         })}

      text == "selected Azure provider/target has cancellation caveats" ->
        {:handled,
         Map.merge(ctx, %{
           provider: AzureQuantum,
           payload: %{workflow: :sampler},
           opts: [
             target: "azure.quantum.sim",
             provider_config: %{
               workspace: "ws-1",
               auth_context: "managed_identity",
               target_id: "azure.quantum.sim",
               provider_name: "microsoft"
             },
             cancellation_caveat: %{
               code: :late_cancel_may_complete,
               detail: "provider may complete running jobs before cancellation takes effect"
             }
           ]
         })}

      text == "an Azure Quantum job is in non-terminal state \"submitted\"" ->
        {:handled,
         Map.put(ctx, :non_terminal_job, %{
           id: "azure_job_1",
           state: :submitted,
           provider: :azure_quantum,
           target: "azure.quantum.sim",
           metadata: %{raw_state: "SUBMITTED"}
         })}

      text == "an Azure Quantum poll operation reaches a transport timeout" ->
        {:handled,
         Map.merge(ctx, %{
           timeout_job: %{
             id: "azure_job_2",
             state: :submitted,
             provider: :azure_quantum,
             target: "azure.quantum.sim",
             metadata: %{raw_state: "SUBMITTED"}
           },
           timeout_opts: [
             force_error: {:poll, :timeout},
             target: "azure.quantum.sim",
             provider_config: %{
               workspace: "ws-1",
               auth_context: "managed_identity",
               target_id: "azure.quantum.sim",
               provider_name: "microsoft"
             }
           ]
         })}

      text == "Azure Quantum adapter returns an unexpected payload for submit" ->
        {:handled,
         Map.merge(ctx, %{
           provider: BrokenAzurePayloadProvider,
           payload: %{workflow: :sampler},
           opts: [
             target: "azure.quantum.sim",
             provider_config: %{
               workspace: "ws-1",
               auth_context: "managed_identity",
               target_id: "azure.quantum.sim",
               provider_name: "microsoft"
             }
           ]
         })}

      true ->
        :unhandled
    end
  end

  defp handle_execution(%{text: text}, ctx) do
    cond do
      text == "configuration validation fails" ->
        result =
          ProviderBridge.submit_job(ctx.provider, ctx.payload,
            target: "azure.quantum.sim",
            provider_config: %{workspace: "ws-1", target_id: "azure.quantum.sim", provider_name: "microsoft"}
          )

        {:handled, Map.put(ctx, :config_result, result)}

      text == "submit, poll, cancel, and fetch_result operations are executed" ->
        {:ok, submitted} = ProviderBridge.submit_job(ctx.provider, ctx.payload, ctx.opts)
        {:ok, polled} = ProviderBridge.poll_job(ctx.provider, submitted, ctx.opts)
        {:ok, cancelled} = ProviderBridge.cancel_job(ctx.provider, submitted, ctx.opts)
        {:ok, result} = ProviderBridge.fetch_result(ctx.provider, polled, ctx.opts)

        {:handled,
         ctx
         |> Map.put(:submit_result, {:ok, submitted})
         |> Map.put(:poll_result, {:ok, polled})
         |> Map.put(:cancel_result, {:ok, cancelled})
         |> Map.put(:fetch_result, {:ok, result})}

      text == "cancellation is requested for a running job" ->
        {:ok, submitted} = ProviderBridge.submit_job(ctx.provider, ctx.payload, ctx.opts)

        {:ok, running} =
          ProviderBridge.poll_job(ctx.provider, submitted, Keyword.put(ctx.opts, :raw_states, %{poll: "EXECUTING"}))

        cancelled = ProviderBridge.cancel_job(ctx.provider, running, ctx.opts)

        mismatch =
          ProviderBridge.submit_job(ctx.provider, ctx.payload,
            target: "azure.quantum.sim",
            provider_target_mismatch: true,
            provider_config: %{
              workspace: "ws-1",
              auth_context: "managed_identity",
              target_id: "azure.quantum.sim",
              provider_name: "microsoft"
            }
          )

        {:handled, ctx |> Map.put(:cancelled_result, cancelled) |> Map.put(:mismatch_result, mismatch)}

      text == "fetch_result is requested" and Map.has_key?(ctx, :non_terminal_job) ->
        {:handled,
         Map.put(ctx, :non_terminal_fetch_result, ProviderBridge.fetch_result(AzureQuantum, ctx.non_terminal_job, []))}

      text == "poll is requested" ->
        {:handled,
         Map.put(ctx, :timeout_result, ProviderBridge.poll_job(AzureQuantum, ctx.timeout_job, ctx.timeout_opts))}

      text == "response normalization is applied" and ctx.provider == BrokenAzurePayloadProvider ->
        {:handled,
         Map.put(ctx, :unexpected_response_result, ProviderBridge.submit_job(ctx.provider, ctx.payload, ctx.opts))}

      true ->
        :unhandled
    end
  end

  defp handle_assertions(%{text: text}, ctx) do
    cond do
      text == "a typed configuration error is returned" ->
        assert {:error, %{code: :provider_auth_error}} = ctx.config_result
        {:handled, ctx}

      text == "error metadata includes workspace, target, and provider context" ->
        assert {:error, %{metadata: metadata}} = ctx.config_result
        assert metadata.provider_config.workspace == "ws-1"
        {:handled, ctx}

      text == "opaque pass-through configuration failures are not allowed" ->
        assert {:error, %{reason: :missing_provider_config}} = ctx.config_result
        {:handled, ctx}

      text == "lifecycle results are returned through normalized NxQuantum envelopes" ->
        assert {:ok, %{provider: :azure_quantum, target: "azure.quantum.sim"}} = ctx.submit_result
        assert {:ok, %{job_id: _, provider: :azure_quantum, target: "azure.quantum.sim"}} = ctx.fetch_result
        {:handled, ctx}

      text == "status mapping is deterministic and preserves raw state metadata" ->
        assert {:ok, %{state: :submitted, metadata: %{raw_state: "SUBMITTED"}}} = ctx.submit_result
        assert {:ok, %{state: :completed, metadata: %{raw_state: "SUCCEEDED"}}} = ctx.poll_result
        {:handled, ctx}

      text == "terminal envelopes remain shape-stable for equivalent requests" ->
        assert {:ok, first} = ctx.fetch_result

        assert {:ok, second} =
                 ProviderBridge.fetch_result(
                   AzureQuantum,
                   %{
                     id: first.job_id,
                     state: :completed,
                     provider: :azure_quantum,
                     target: "azure.quantum.sim",
                     metadata: %{raw_state: "SUCCEEDED"}
                   },
                   ctx.opts
                 )

        assert Map.keys(first) == Map.keys(second)
        {:handled, ctx}

      text == "caveat metadata is included in typed result context" ->
        assert {:ok, %{metadata: %{cancellation_caveat: caveat}}} = ctx.cancelled_result
        assert caveat.code == :late_cancel_may_complete
        {:handled, ctx}

      text == "cancellation semantics are explicit and not hidden" ->
        assert {:ok, %{state: :cancelled}} = ctx.cancelled_result
        {:handled, ctx}

      text == "provider/target mismatch failures map to capability errors" ->
        assert {:error, %{code: :provider_capability_mismatch, capability: :target_provider_match}} = ctx.mismatch_result
        {:handled, ctx}

      text == "error metadata includes operation \"fetch_result\" and current job state" ->
        assert {:error, %{operation: :fetch_result, state: :submitted}} = ctx.non_terminal_fetch_result
        {:handled, ctx}

      text == "error metadata includes operation \"poll\" and provider identifier" ->
        assert {:error, %{operation: :poll, provider: :azure_quantum}} = ctx.timeout_result
        {:handled, ctx}

      text == "diagnostics include operation \"submit\"" ->
        assert {:error, %{operation: :submit}} = ctx.unexpected_response_result
        {:handled, ctx}

      true ->
        :unhandled
    end
  end

  defp handle_errors(%{text: text}, ctx) do
    if text =~ ~r/^error / and text =~ ~r/ is returned$/ do
      expected = text |> NxQuantum.TestSupport.Helpers.parse_quoted() |> String.to_atom()

      candidate =
        Map.get(ctx, :non_terminal_fetch_result) ||
          Map.get(ctx, :timeout_result) ||
          Map.get(ctx, :unexpected_response_result)

      assert {:error, %{code: ^expected}} = candidate
      {:handled, ctx}
    else
      :unhandled
    end
  end
end
