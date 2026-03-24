defmodule NxQuantum.Adapters.Providers.Common.LiveTransport do
  @moduledoc false

  @type operation :: :submit | :poll | :cancel | :fetch_result

  @spec lifecycle(atom(), operation(), map(), keyword()) :: {:ok, map()} | {:error, term()}
  def lifecycle(provider, operation, payload, opts) when is_atom(operation) and is_map(payload) and is_list(opts) do
    with {:ok, body} <- resolve_response(provider, operation, payload, opts) do
      {:ok,
       %{
         raw_state: Map.get(body, "raw_state", default_state(operation)),
         payload: Map.get(body, "payload"),
         metadata: Map.get(body, "metadata", %{}),
         provider_job_id: Map.get(body, "provider_job_id"),
         provider_error_code: Map.get(body, "provider_error_code")
       }}
    end
  end

  defp resolve_response(provider, operation, payload, opts) do
    live_responses = Keyword.get(opts, :live_responses, %{})

    case Map.get(live_responses, operation) do
      %{} = response ->
        {:ok, stringify_map(response)}

      nil ->
        do_http(provider, operation, payload, opts)

      _other ->
        {:error, {:invalid_response, operation, :invalid_live_response}}
    end
  end

  defp do_http(provider, operation, payload, opts) do
    with {:ok, url} <- endpoint_url(operation, opts),
         {:ok, response} <- http_post(url, %{provider: provider, operation: operation, payload: payload}, opts) do
      {:ok, stringify_map(response)}
    end
  end

  defp endpoint_url(operation, opts) do
    provider_config = Keyword.get(opts, :provider_config, %{})

    cond do
      is_binary(Map.get(provider_config, :base_url)) ->
        {:ok, "#{provider_config.base_url}/#{operation}"}

      is_binary(Keyword.get(opts, :live_endpoint)) ->
        {:ok, Keyword.fetch!(opts, :live_endpoint)}

      true ->
        {:error, {:provider_transport_error, :missing_live_endpoint}}
    end
  end

  defp http_post(url, payload, opts) do
    case Keyword.get(opts, :live_http_fun) do
      fun when is_function(fun, 3) ->
        case fun.(url, payload, opts) do
          {:ok, %{} = response} -> {:ok, response}
          {:error, reason} -> {:error, reason}
          other -> {:error, {:provider_invalid_response, other}}
        end

      _ ->
        {:error, {:provider_transport_error, :missing_live_http_fun}}
    end
  end

  defp default_state(:submit), do: "SUBMITTED"
  defp default_state(:poll), do: "COMPLETED"
  defp default_state(:cancel), do: "CANCELLED"
  defp default_state(:fetch_result), do: "COMPLETED"

  defp stringify_map(%{} = map) do
    Map.new(map, fn {k, v} -> {to_string(k), stringify_value(v)} end)
  end

  defp stringify_value(%{} = map), do: stringify_map(map)
  defp stringify_value(list) when is_list(list), do: Enum.map(list, &stringify_value/1)
  defp stringify_value(v) when is_atom(v), do: Atom.to_string(v)
  defp stringify_value(v), do: v
end
