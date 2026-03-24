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
         {:ok, body} <- encode_body(%{provider: provider, operation: operation, payload: payload}),
         {:ok, response} <- http_post(url, body, opts) do
      decode_response(response)
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

  defp encode_body(map), do: {:ok, :erlang.term_to_binary(stringify_map(map), [:deterministic])}

  defp decode_response({status, raw_body}) when is_integer(status) and status in 200..299 do
    {:ok, raw_body |> :erlang.binary_to_term() |> stringify_map()}
  rescue
    _ -> {:error, {:provider_invalid_response, :live_transport_decode_failed}}
  end

  defp decode_response({status, _raw_body}) when status in [401, 403], do: {:error, {:provider_auth_error, :unauthorized}}

  defp decode_response({429, _raw_body}), do: {:error, {:provider_rate_limited, :rate_limited}}
  defp decode_response({status, raw_body}), do: {:error, {:provider_transport_error, {:http_status, status, raw_body}}}

  defp http_post(url, body, opts) do
    headers =
      opts
      |> Keyword.get(:provider_config, %{})
      |> auth_header()
      |> then(&[{"content-type", "application/octet-stream"} | &1])

    request = {String.to_charlist(url), headers, ~c"application/octet-stream", body}
    timeout = Keyword.get(opts, :live_timeout_ms, 5_000)
    http_opts = [timeout: timeout]

    :inets.start()
    :ssl.start()

    case :httpc.request(:post, request, http_opts, body_format: :binary) do
      {:ok, {{_http_version, status, _reason}, _resp_headers, resp_body}} -> {:ok, {status, resp_body}}
      {:error, reason} -> {:error, {:provider_transport_error, reason}}
    end
  end

  defp auth_header(%{auth_token: token}) when is_binary(token), do: [{"authorization", "Bearer " <> token}]
  defp auth_header(%{api_key: key}) when is_binary(key), do: [{"x-api-key", key}]
  defp auth_header(_), do: []

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
