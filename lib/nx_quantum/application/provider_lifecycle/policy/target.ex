defmodule NxQuantum.Application.ProviderLifecycle.Policy.Target do
  @moduledoc false

  alias NxQuantum.ProviderBridge.Errors

  @spec run(keyword(), atom() | String.t() | module(), String.t() | nil) :: :ok | {:error, map()}
  def run(opts, provider, target) do
    if Keyword.get(opts, :provider_target_mismatch, false) do
      config = Keyword.get(opts, :provider_config, %{})

      {:error,
       Errors.capability_mismatch(:submit, provider, :target_provider_match,
         metadata: %{
           provider: provider,
           target: target,
           workspace: Map.get(config, :workspace),
           provider_name: Map.get(config, :provider_name)
         }
       )}
    else
      :ok
    end
  end
end
