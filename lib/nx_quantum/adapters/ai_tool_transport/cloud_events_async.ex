defmodule NxQuantum.Adapters.AIToolTransport.CloudEventsAsync do
  @moduledoc """
  Async transport adapter scaffold for CloudEvents-driven tool execution.

  The scaffold models dispatch and polling contracts without coupling NxQuantum
  to a specific broker implementation in Phase 19.
  """

  @behaviour NxQuantum.Ports.AIToolTransport

  @supported_modes [:async]
  @requested_event_type "nxq.ai.tool.requested.v1"

  @impl true
  def transport_id, do: :cloud_events_async

  @impl true
  def capabilities(_opts) do
    %{
      modes: @supported_modes,
      protocol: :cloudevents,
      spec_version: "1.0",
      metadata: %{delivery_semantics: :at_least_once}
    }
  end

  @impl true
  def invoke_sync(request, _opts) when is_map(request) do
    {:error, mode_unsupported_error(:invoke_sync, request)}
  end

  @impl true
  def publish_async(request, opts) when is_map(request) and is_list(opts) do
    dispatch_id = Keyword.get_lazy(opts, :dispatch_id, fn -> build_dispatch_id(request) end)

    {:ok,
     %{
       dispatch_id: dispatch_id,
       status: :accepted,
       request_id: Map.get(request, :request_id),
       correlation_id: Map.get(request, :correlation_id),
       metadata: %{
         adapter: transport_id(),
         event_type: @requested_event_type,
         delivery_semantics: :at_least_once,
         scaffold: true
       }
     }}
  end

  @impl true
  def fetch_async_result(dispatch_ref, opts) when is_list(opts) do
    dispatch_id = extract_dispatch_id(dispatch_ref)

    cond do
      is_map(opts[:stub_terminal_result]) ->
        {:ok,
         %{
           dispatch_id: dispatch_id,
           status: :ok,
           result: opts[:stub_terminal_result],
           metadata: %{adapter: transport_id(), scaffold: true}
         }}

      is_map(opts[:stub_terminal_error]) ->
        {:ok,
         %{
           dispatch_id: dispatch_id,
           status: :error,
           error: opts[:stub_terminal_error],
           metadata: %{adapter: transport_id(), scaffold: true}
         }}

      true ->
        {:ok,
         %{
           dispatch_id: dispatch_id,
           status: :pending,
           metadata: %{adapter: transport_id(), scaffold: true}
         }}
    end
  end

  @impl true
  def cancel_async(_dispatch_ref, _opts), do: :ok

  defp mode_unsupported_error(operation, request_or_ref) do
    %{
      code: :ai_transport_mode_unsupported,
      category: :capability,
      retryable: false,
      message: "operation is not supported by async-only transport adapter",
      details: %{
        adapter: transport_id(),
        operation: operation,
        supported_modes: @supported_modes,
        request_id: extract_request_id(request_or_ref),
        dispatch_id: extract_dispatch_id(request_or_ref)
      }
    }
  end

  defp build_dispatch_id(request) do
    request
    |> :erlang.term_to_binary()
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
    |> binary_part(0, 16)
    |> then(&("nxq-ce-" <> &1))
  end

  defp extract_request_id(%{request_id: request_id}), do: request_id
  defp extract_request_id(_), do: nil

  defp extract_dispatch_id(%{dispatch_id: dispatch_id}) when is_binary(dispatch_id), do: dispatch_id
  defp extract_dispatch_id(dispatch_id) when is_binary(dispatch_id), do: dispatch_id
  defp extract_dispatch_id(_), do: "nxq-ce-unknown"
end
