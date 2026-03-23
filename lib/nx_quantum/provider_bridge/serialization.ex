defmodule NxQuantum.ProviderBridge.Serialization do
  @moduledoc """
  Deterministic external-operations serialization helpers for provider envelopes.
  """

  alias NxQuantum.ProviderBridge.Job
  alias NxQuantum.ProviderBridge.ProviderError
  alias NxQuantum.ProviderBridge.Result

  @schema_version :v1

  @spec schema_version() :: :v1
  def schema_version, do: @schema_version

  @spec to_external_map(Job.t() | Result.t() | ProviderError.t() | map()) :: map()
  def to_external_map(%Job{} = job) do
    %{
      "schema_version" => version_string(job.schema_version || @schema_version),
      "type" => "job",
      "id" => job.id,
      "state" => to_string(job.state),
      "provider" => provider_value(job.provider),
      "target" => job.target,
      "submitted_at" => job.submitted_at,
      "correlation_id" => job.correlation_id,
      "idempotency_key" => job.idempotency_key,
      "metadata" => stringify_keys(job.metadata || %{})
    }
  end

  def to_external_map(%Result{} = result) do
    %{
      "schema_version" => version_string(result.schema_version || @schema_version),
      "type" => "result",
      "job_id" => result.job_id,
      "state" => to_string(result.state),
      "provider" => provider_value(result.provider),
      "target" => result.target,
      "correlation_id" => result.correlation_id,
      "idempotency_key" => result.idempotency_key,
      "payload" => stringify_keys(result.payload || %{}),
      "metadata" => stringify_keys(result.metadata || %{})
    }
  end

  def to_external_map(%ProviderError{} = error) do
    %{
      "schema_version" => version_string(error.schema_version || @schema_version),
      "type" => "error",
      "code" => to_string(error.code),
      "operation" => to_string(error.operation),
      "provider" => provider_value(error.provider),
      "reason" => stringify_value(error.reason),
      "state" => stringify_value(error.state),
      "capability" => stringify_value(error.capability),
      "response" => stringify_value(error.response),
      "correlation_id" => error.correlation_id,
      "idempotency_key" => error.idempotency_key,
      "metadata" => stringify_keys(error.metadata || %{})
    }
  end

  def to_external_map(%{} = envelope), do: stringify_keys(envelope)

  @spec serialize(Job.t() | Result.t() | ProviderError.t() | map()) :: {:ok, String.t()}
  def serialize(envelope) do
    encoded =
      envelope
      |> to_external_map()
      |> :erlang.term_to_binary([:deterministic])
      |> Base.url_encode64(padding: false)

    {:ok, encoded}
  end

  defp version_string(version) when is_atom(version), do: Atom.to_string(version)
  defp version_string(version) when is_binary(version), do: version

  defp provider_value(provider) when is_atom(provider), do: Atom.to_string(provider)
  defp provider_value(provider) when is_binary(provider), do: provider
  defp provider_value(provider), do: inspect(provider)

  defp stringify_keys(%{} = map) do
    map
    |> Enum.sort_by(fn {key, _value} -> to_string(key) end)
    |> Map.new(fn {key, value} -> {to_string(key), stringify_value(value)} end)
  end

  defp stringify_value(%{} = map), do: stringify_keys(map)
  defp stringify_value(list) when is_list(list), do: Enum.map(list, &stringify_value/1)
  defp stringify_value(value) when is_atom(value), do: Atom.to_string(value)
  defp stringify_value(%Nx.Tensor{} = tensor), do: inspect(tensor)
  defp stringify_value(value), do: value
end
