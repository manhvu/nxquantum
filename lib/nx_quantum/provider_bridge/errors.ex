defmodule NxQuantum.ProviderBridge.Errors do
  @moduledoc false

  alias NxQuantum.ProviderBridge.ProviderError

  @spec transport_error(atom(), atom() | String.t(), term(), keyword()) :: ProviderError.t()
  def transport_error(operation, provider, reason, opts \\ []) do
    base(
      %ProviderError{
        code: :provider_transport_error,
        operation: operation,
        provider: provider,
        reason: reason
      },
      opts
    )
  end

  @spec auth_error(atom(), atom() | String.t(), term(), keyword()) :: ProviderError.t()
  def auth_error(operation, provider, reason, opts \\ []) do
    base(%ProviderError{code: :provider_auth_error, operation: operation, provider: provider, reason: reason}, opts)
  end

  @spec invalid_state(atom(), atom() | String.t(), atom(), keyword()) :: ProviderError.t()
  def invalid_state(operation, provider, state, opts \\ []) do
    base(
      %ProviderError{
        code: :provider_invalid_state,
        operation: operation,
        provider: provider,
        state: state
      },
      opts
    )
  end

  @spec invalid_response(atom(), atom() | String.t(), term(), keyword()) :: ProviderError.t()
  def invalid_response(operation, provider, response, opts \\ []) do
    base(
      %ProviderError{
        code: :provider_invalid_response,
        operation: operation,
        provider: provider,
        response: response
      },
      opts
    )
  end

  @spec capability_mismatch(atom(), atom() | String.t(), atom(), keyword()) :: ProviderError.t()
  def capability_mismatch(operation, provider, capability, opts \\ []) do
    base(
      %ProviderError{
        code: :provider_capability_mismatch,
        operation: operation,
        provider: provider,
        capability: capability
      },
      opts
    )
  end

  @spec execution_error(atom(), atom() | String.t(), term(), keyword()) :: ProviderError.t()
  def execution_error(operation, provider, reason, opts \\ []) do
    base(
      %ProviderError{
        code: :provider_execution_error,
        operation: operation,
        provider: provider,
        reason: reason
      },
      opts
    )
  end

  @spec rate_limited(atom(), atom() | String.t(), term(), keyword()) :: ProviderError.t()
  def rate_limited(operation, provider, reason, opts \\ []) do
    base(
      %ProviderError{
        code: :provider_rate_limited,
        operation: operation,
        provider: provider,
        reason: reason
      },
      opts
    )
  end

  defp base(map, opts) do
    metadata = Keyword.get(opts, :metadata, %{})
    %{map | metadata: metadata}
  end
end
