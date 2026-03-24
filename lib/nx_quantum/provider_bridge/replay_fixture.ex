defmodule NxQuantum.ProviderBridge.ReplayFixture do
  @moduledoc """
  Live-run replay fixture capture for deterministic regression lanes.
  """

  alias NxQuantum.ProviderBridge.Job
  alias NxQuantum.ProviderBridge.ProviderError
  alias NxQuantum.ProviderBridge.Result

  @schema_version :v1

  @spec capture(map()) :: {:ok, map()} | {:error, map()}
  def capture(%{submitted: %Job{} = submitted, polled: %Job{} = polled, result: %Result{} = result} = input) do
    fixture = %{
      schema_version: @schema_version,
      captured_at: DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601(),
      provider: submitted.provider,
      target: submitted.target,
      request_id: submitted.request_id || result.request_id,
      correlation_id: submitted.correlation_id || result.correlation_id,
      idempotency_key: submitted.idempotency_key || result.idempotency_key,
      provenance: Map.get(input, :provenance, %{}),
      submit: sanitize_job(submitted),
      poll: sanitize_job(polled),
      fetch_result: sanitize_result(result)
    }

    {:ok, fixture}
  end

  def capture(%{error: %ProviderError{} = error}) do
    {:ok,
     %{
       schema_version: @schema_version,
       captured_at: DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601(),
       provider: error.provider,
       request_id: error.request_id,
       correlation_id: error.correlation_id,
       idempotency_key: error.idempotency_key,
       error: sanitize_error(error)
     }}
  end

  def capture(_other), do: {:error, %{code: :invalid_replay_fixture_input}}

  @spec write(map(), Path.t()) :: :ok | {:error, term()}
  def write(fixture, path) when is_binary(path) do
    with {:ok, term} <- fixture |> :erlang.term_to_binary([:deterministic]) |> then(&{:ok, &1}),
         :ok <- File.mkdir_p(Path.dirname(path)) do
      File.write(path, Base.encode64(term))
    end
  end

  defp sanitize_job(%Job{} = job) do
    %{
      id: job.id,
      state: job.state,
      provider_job_id: job.metadata[:provider_job_id],
      metadata: Map.take(job.metadata || %{}, [:raw_state, :provider_error_code, :queue_phase, :terminal_diagnostics])
    }
  end

  defp sanitize_result(%Result{} = result) do
    %{
      job_id: result.job_id,
      state: result.state,
      payload: result.payload,
      metadata:
        Map.take(result.metadata || %{}, [
          :provider_payload_version,
          :provider_job_id,
          :provider_error_code,
          :terminal_diagnostics,
          :queue_phase
        ])
    }
  end

  defp sanitize_error(%ProviderError{} = error) do
    %{
      code: error.code,
      operation: error.operation,
      reason: error.reason,
      metadata: Map.take(error.metadata || %{}, [:provider_error_code, :retryable, :queue_phase, :terminal_diagnostics])
    }
  end
end
