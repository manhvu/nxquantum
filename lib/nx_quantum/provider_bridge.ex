defmodule NxQuantum.ProviderBridge do
  @moduledoc """
  Provider lifecycle facade with typed deterministic error mapping.
  """
  alias NxQuantum.Application.ProviderLifecycle.Runner
  alias NxQuantum.ProviderBridge.Job
  alias NxQuantum.ProviderBridge.ProviderError
  alias NxQuantum.ProviderBridge.Result

  @spec submit_job(module(), map(), keyword()) :: {:ok, Job.t()} | {:error, ProviderError.t()}
  def submit_job(provider_adapter, payload, opts \\ []) do
    Runner.submit_job(provider_adapter, payload, opts)
  end

  @spec poll_job(module(), map(), keyword()) :: {:ok, Job.t()} | {:error, ProviderError.t()}
  def poll_job(provider_adapter, job, opts \\ []) do
    Runner.poll_job(provider_adapter, job, opts)
  end

  @spec cancel_job(module(), map(), keyword()) :: {:ok, Job.t()} | {:error, ProviderError.t()}
  def cancel_job(provider_adapter, job, opts \\ []) do
    Runner.cancel_job(provider_adapter, job, opts)
  end

  @spec fetch_result(module(), map(), keyword()) :: {:ok, Result.t()} | {:error, ProviderError.t()}
  def fetch_result(provider_adapter, job, opts \\ []) do
    Runner.fetch_result(provider_adapter, job, opts)
  end

  @spec run_lifecycle(module(), map(), keyword()) :: {:ok, map()} | {:error, map()}
  def run_lifecycle(provider_adapter, payload, opts \\ []) do
    Runner.run_lifecycle(provider_adapter, payload, opts)
  end
end
