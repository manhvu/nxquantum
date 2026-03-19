defmodule NxQuantum.ProviderBridge.Errors do
  @moduledoc false

  @spec transport_error(atom(), atom() | String.t(), term()) :: map()
  def transport_error(operation, provider, reason) do
    %{code: :provider_transport_error, operation: operation, provider: provider, reason: reason}
  end

  @spec invalid_state(atom(), atom() | String.t(), atom()) :: map()
  def invalid_state(operation, provider, state) do
    %{code: :provider_invalid_state, operation: operation, provider: provider, state: state}
  end

  @spec invalid_response(atom(), atom() | String.t(), term()) :: map()
  def invalid_response(operation, provider, response) do
    %{code: :provider_invalid_response, operation: operation, provider: provider, response: response}
  end

  @spec provider_error(atom(), atom() | String.t(), term()) :: map()
  def provider_error(operation, provider, reason) do
    %{code: :provider_error, operation: operation, provider: provider, reason: reason}
  end
end
