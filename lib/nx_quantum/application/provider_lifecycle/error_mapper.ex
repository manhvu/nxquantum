defmodule NxQuantum.Application.ProviderLifecycle.ErrorMapper do
  @moduledoc false

  alias NxQuantum.ProviderBridge.Errors
  alias NxQuantum.ProviderBridge.ProviderError

  @spec map_error(term(), atom(), atom() | String.t() | module()) :: ProviderError.t()
  def map_error(:timeout, operation, provider) do
    Errors.transport_error(operation, provider, :timeout)
  end

  def map_error({:provider_auth_error, reason}, operation, provider) do
    Errors.auth_error(operation, provider, reason)
  end

  def map_error({:provider_rate_limited, reason}, operation, provider) do
    Errors.rate_limited(operation, provider, reason)
  end

  def map_error({:provider_capability_mismatch, capability}, operation, provider) do
    Errors.capability_mismatch(operation, provider, capability)
  end

  def map_error({:invalid_response, _source, response}, operation, provider) do
    Errors.invalid_response(operation, provider, response)
  end

  def map_error({:invalid_state, state}, operation, provider) do
    Errors.invalid_state(operation, provider, state)
  end

  def map_error(%ProviderError{} = error, operation, provider) do
    %{error | operation: error.operation || operation, provider: error.provider || provider}
  end

  def map_error(%{code: _} = error, operation, provider) do
    struct(ProviderError, Map.merge(%{operation: operation, provider: provider, metadata: %{}}, error))
  end

  def map_error(reason, operation, provider) do
    Errors.execution_error(operation, provider, reason)
  end
end
