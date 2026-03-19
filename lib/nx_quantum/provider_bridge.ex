alias NxQuantum.ProviderBridge.Errors

defmodule NxQuantum.ProviderBridge do
  @moduledoc """
  Provider lifecycle facade with typed deterministic error mapping.
  """

  @spec submit_job(module(), map(), keyword()) :: {:ok, map()} | {:error, map()}
  def submit_job(provider_adapter, payload, opts \\ []) do
    provider_call(provider_adapter, :submit, [payload, opts], :submit)
  end

  @spec poll_job(module(), map(), keyword()) :: {:ok, map()} | {:error, map()}
  def poll_job(provider_adapter, job, opts \\ []) do
    provider_call(provider_adapter, :poll, [job, opts], :poll)
  end

  @spec cancel_job(module(), map(), keyword()) :: {:ok, map()} | {:error, map()}
  def cancel_job(provider_adapter, job, opts \\ []) do
    provider_call(provider_adapter, :cancel, [job, opts], :cancel)
  end

  @spec fetch_result(module(), map(), keyword()) :: {:ok, map()} | {:error, map()}
  def fetch_result(provider_adapter, job, opts \\ []) do
    provider_call(provider_adapter, :fetch_result, [job, opts], :fetch_result)
  end

  @spec run_lifecycle(module(), map(), keyword()) :: {:ok, map()} | {:error, map()}
  def run_lifecycle(provider_adapter, payload, opts \\ []) do
    with {:ok, submitted} <- submit_job(provider_adapter, payload, opts),
         {:ok, polled} <- poll_job(provider_adapter, submitted, opts),
         {:ok, result} <- fetch_result(provider_adapter, polled, opts) do
      {:ok, %{submitted: submitted, polled: polled, result: result}}
    end
  end

  defp provider_call(provider_adapter, fun, args, operation) do
    provider_id = provider_id(provider_adapter)

    try do
      case apply(provider_adapter, fun, args) do
        {:ok, value} ->
          {:ok, value}

        {:error, reason} ->
          {:error, map_error(reason, operation, provider_id)}

        unexpected ->
          {:error, Errors.invalid_response(operation, provider_id, unexpected)}
      end
    rescue
      error ->
        {:error, Errors.transport_error(operation, provider_id, Exception.message(error))}
    end
  end

  defp provider_id(provider_adapter) do
    if function_exported?(provider_adapter, :provider_id, 0) do
      provider_adapter.provider_id()
    else
      provider_adapter
    end
  end

  defp map_error(:timeout, operation, provider) do
    Errors.transport_error(operation, provider, :timeout)
  end

  defp map_error({:invalid_state, state}, operation, provider) do
    Errors.invalid_state(operation, provider, state)
  end

  defp map_error(reason, operation, provider) do
    Errors.provider_error(operation, provider, reason)
  end
end
