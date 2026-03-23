defmodule NxQuantum.Adapters.AIToolTransport.McpJsonRpcSync do
  @moduledoc """
  Sync transport adapter scaffold for MCP/JSON-RPC request/response flows.

  This adapter intentionally keeps execution behavior explicit:

  - sync mode is supported
  - async operations fail fast with typed deterministic errors
  """

  @behaviour NxQuantum.Ports.AIToolTransport

  @supported_modes [:sync]

  @impl true
  def transport_id, do: :mcp_json_rpc_sync

  @impl true
  def capabilities(_opts) do
    %{modes: @supported_modes, protocol: :json_rpc, spec_version: "2.0", metadata: %{transport: :mcp}}
  end

  @impl true
  def invoke_sync(request, opts) when is_map(request) and is_list(opts) do
    case Keyword.fetch(opts, :stub_result_envelope) do
      {:ok, result} when is_map(result) -> {:ok, result}
      _ -> {:error, not_configured_error(:invoke_sync, request)}
    end
  end

  @impl true
  def publish_async(request, _opts) when is_map(request) do
    {:error, mode_unsupported_error(:publish_async, request)}
  end

  @impl true
  def fetch_async_result(dispatch_ref, _opts) do
    {:error, mode_unsupported_error(:fetch_async_result, dispatch_ref)}
  end

  @impl true
  def cancel_async(dispatch_ref, _opts) do
    {:error, mode_unsupported_error(:cancel_async, dispatch_ref)}
  end

  defp not_configured_error(operation, request) do
    %{
      code: :ai_transport_not_configured,
      category: :transport,
      retryable: false,
      message: "MCP/JSON-RPC sync adapter scaffold is not configured for live dispatch",
      details: %{
        adapter: transport_id(),
        operation: operation,
        request_id: Map.get(request, :request_id),
        correlation_id: Map.get(request, :correlation_id),
        supported_modes: @supported_modes
      }
    }
  end

  defp mode_unsupported_error(operation, request_or_ref) do
    %{
      code: :ai_transport_mode_unsupported,
      category: :capability,
      retryable: false,
      message: "operation is not supported by sync-only transport adapter",
      details: %{
        adapter: transport_id(),
        operation: operation,
        supported_modes: @supported_modes,
        request_id: extract_request_id(request_or_ref),
        dispatch_id: extract_dispatch_id(request_or_ref)
      }
    }
  end

  defp extract_request_id(%{request_id: request_id}), do: request_id
  defp extract_request_id(_), do: nil

  defp extract_dispatch_id(%{dispatch_id: dispatch_id}), do: dispatch_id
  defp extract_dispatch_id(dispatch_id) when is_binary(dispatch_id), do: dispatch_id
  defp extract_dispatch_id(_), do: nil
end
