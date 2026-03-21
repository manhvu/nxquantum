defmodule NxQuantum.Application.ProviderLifecycle.Runner do
  @moduledoc false

  alias NxQuantum.Application.ProviderLifecycle.Commands.Cancel
  alias NxQuantum.Application.ProviderLifecycle.Commands.FetchResult
  alias NxQuantum.Application.ProviderLifecycle.Commands.Poll
  alias NxQuantum.Application.ProviderLifecycle.Commands.Submit
  alias NxQuantum.Application.ProviderLifecycle.Dispatcher
  alias NxQuantum.Application.ProviderLifecycle.Preflight
  alias NxQuantum.Observability
  alias NxQuantum.ProviderBridge.Job

  @spec submit_job(module(), map(), keyword()) :: {:ok, map()} | {:error, map()}
  def submit_job(provider_adapter, payload, opts) do
    with :ok <- Preflight.run(provider_adapter, payload, opts) do
      Dispatcher.dispatch(provider_adapter, Submit, [payload, opts], opts)
    end
  end

  @spec poll_job(module(), map(), keyword()) :: {:ok, map()} | {:error, map()}
  def poll_job(provider_adapter, job, opts) do
    Dispatcher.dispatch(provider_adapter, Poll, [normalize_job(job), opts], opts)
  end

  @spec cancel_job(module(), map(), keyword()) :: {:ok, map()} | {:error, map()}
  def cancel_job(provider_adapter, job, opts) do
    Dispatcher.dispatch(provider_adapter, Cancel, [normalize_job(job), opts], opts)
  end

  @spec fetch_result(module(), map(), keyword()) :: {:ok, map()} | {:error, map()}
  def fetch_result(provider_adapter, job, opts) do
    Dispatcher.dispatch(provider_adapter, FetchResult, [normalize_job(job), opts], opts)
  end

  @spec run_lifecycle(module(), map(), keyword()) :: {:ok, map()} | {:error, map()}
  def run_lifecycle(provider_adapter, payload, opts) do
    provider = Dispatcher.provider_id(provider_adapter)
    target = Keyword.get(opts, :target, "unknown_target")
    workflow = Map.get(payload, :workflow, :unknown_workflow)

    Observability.trace_workflow(provider, target, workflow, Keyword.get(opts, :observability, []), fn ->
      with {:ok, submitted} <- submit_job(provider_adapter, payload, opts),
           {:ok, polled} <- poll_job(provider_adapter, submitted, opts),
           {:ok, result} <- fetch_result(provider_adapter, polled, opts) do
        {:ok, %{submitted: submitted, polled: polled, result: result}}
      end
    end)
  end

  defp normalize_job(%Job{} = job), do: job

  defp normalize_job(%{} = map) do
    metadata =
      map
      |> Map.get(:metadata, %{})
      |> ensure_metadata_map()
      |> maybe_put_legacy(:simulate_timeout, map)
      |> maybe_put_legacy(:payload, map)

    map
    |> Map.put(:metadata, metadata)
    |> then(&struct(Job, &1))
  end

  defp ensure_metadata_map(value) when is_map(value), do: value
  defp ensure_metadata_map(_), do: %{}

  defp maybe_put_legacy(metadata, key, map) do
    case {Map.has_key?(metadata, key), Map.fetch(map, key)} do
      {false, {:ok, value}} -> Map.put(metadata, key, value)
      _ -> metadata
    end
  end
end
