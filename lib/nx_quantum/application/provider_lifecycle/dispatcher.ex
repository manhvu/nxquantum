defmodule NxQuantum.Application.ProviderLifecycle.Dispatcher do
  @moduledoc false

  alias NxQuantum.Application.ProviderLifecycle.ErrorMapper
  alias NxQuantum.Observability
  alias NxQuantum.ProviderBridge.Errors

  @spec dispatch(module(), module(), [term()], keyword()) :: {:ok, map()} | {:error, map()}
  def dispatch(provider_adapter, command_module, args, opts) do
    provider = provider_id(provider_adapter)
    operation = command_module.operation()
    adapter_fun = command_module.adapter_fun()
    {target, workflow, obs_opts} = command_module.context(args, opts)

    Observability.trace_lifecycle(operation, provider, target, workflow, obs_opts, fn ->
      try do
        case apply(provider_adapter, adapter_fun, args) do
          {:ok, value} -> {:ok, value}
          {:error, reason} -> {:error, ErrorMapper.map_error(reason, operation, provider)}
          unexpected -> {:error, Errors.invalid_response(operation, provider, unexpected)}
        end
      rescue
        error ->
          {:error, Errors.transport_error(operation, provider, Exception.message(error))}
      end
    end)
  end

  @spec provider_id(module()) :: atom() | String.t() | module()
  def provider_id(provider_adapter) do
    if function_exported?(provider_adapter, :provider_id, 0) do
      provider_adapter.provider_id()
    else
      provider_adapter
    end
  end
end
