defmodule NxQuantum.Application.ProviderLifecycle.Preflight do
  @moduledoc false

  alias NxQuantum.Application.ProviderLifecycle.Dispatcher
  alias NxQuantum.Application.ProviderLifecycle.Policy.Target
  alias NxQuantum.Application.ProviderLifecycle.Policy.Workflow
  alias NxQuantum.ProviderBridge.CapabilityContract
  alias NxQuantum.Providers.Capabilities

  @spec run(module(), map(), keyword()) :: :ok | {:error, map()}
  def run(provider_adapter, payload, opts) do
    contract_version = Keyword.get(opts, :capability_contract, :v1)
    target = Keyword.get(opts, :target)
    provider = Dispatcher.provider_id(provider_adapter)
    request = request_envelope(payload, opts)

    with :ok <- Workflow.run(request, provider, target),
         :ok <- Target.run(opts, provider, target),
         {:ok, validated} <- fetch_and_validate_capabilities(provider_adapter, provider, target, contract_version, opts),
         :ok <- Capabilities.preflight(validated, request, provider, target) do
      :ok
    else
      :skip -> :ok
      {:error, _} = error -> error
    end
  end

  defp fetch_capabilities(provider_adapter, target, opts) do
    if function_exported?(provider_adapter, :capabilities, 2) do
      provider_adapter.capabilities(target, opts)
    else
      :skip
    end
  end

  defp fetch_and_validate_capabilities(provider_adapter, provider, target, contract_version, opts) do
    case fetch_capabilities(provider_adapter, target, opts) do
      {:ok, %CapabilityContract{} = contract} ->
        {:ok, contract}

      {:ok, capabilities} ->
        Capabilities.validate_contract(capabilities, provider, contract_version, target)

      :skip ->
        :skip

      {:error, _} = error ->
        error
    end
  end

  defp request_envelope(payload, opts) do
    %{
      workflow: Map.get(payload, :workflow, Keyword.get(opts, :workflow)),
      dynamic: Map.get(payload, :dynamic, Keyword.get(opts, :dynamic, false)),
      batch: Map.get(payload, :batch, Keyword.get(opts, :batch, false)),
      calibration_payload: Map.get(payload, :calibration_payload, Keyword.get(opts, :calibration_payload))
    }
  end
end
