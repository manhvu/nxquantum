defmodule NxQuantum.AIToolTransportContractTest do
  use ExUnit.Case, async: true

  alias NxQuantum.Adapters.AIToolTransport.CloudEventsAsync
  alias NxQuantum.Adapters.AIToolTransport.McpJsonRpcSync

  @request %{
    schema_version: "v1",
    request_id: "req-123",
    correlation_id: "corr-123",
    tool_name: "quantum_kernel_rerank.v1",
    input: %{candidate_ids: ["a", "b"]}
  }

  test "sync adapter exposes sync-only capability contract" do
    capabilities = McpJsonRpcSync.capabilities([])

    assert capabilities.modes == [:sync]
    assert capabilities.protocol == :json_rpc
    assert capabilities.spec_version == "2.0"
  end

  test "sync adapter rejects async operations with typed deterministic error" do
    assert {:error, %{code: :ai_transport_mode_unsupported, category: :capability}} =
             McpJsonRpcSync.publish_async(@request, [])

    assert {:error, %{code: :ai_transport_mode_unsupported, category: :capability}} =
             McpJsonRpcSync.fetch_async_result(%{dispatch_id: "d-1"}, [])
  end

  test "sync adapter can return stub result envelope for contract testing" do
    stub_result = %{schema_version: "v1", request_id: "req-123", status: :ok, output: %{scores: [0.8]}}

    assert {:ok, ^stub_result} =
             McpJsonRpcSync.invoke_sync(@request, stub_result_envelope: stub_result)
  end

  test "async adapter exposes async-only capability contract" do
    capabilities = CloudEventsAsync.capabilities([])

    assert capabilities.modes == [:async]
    assert capabilities.protocol == :cloudevents
    assert capabilities.spec_version == "1.0"
  end

  test "async adapter publishes deterministic dispatch id for identical request" do
    assert {:ok, first} = CloudEventsAsync.publish_async(@request, [])
    assert {:ok, second} = CloudEventsAsync.publish_async(@request, [])

    assert first.dispatch_id == second.dispatch_id
    assert first.status == :accepted
    assert String.starts_with?(first.dispatch_id, "nxq-ce-")
  end

  test "async adapter returns pending by default and supports deterministic terminal fixtures" do
    assert {:ok, dispatch} = CloudEventsAsync.publish_async(@request, [])

    assert {:ok, %{status: :pending, dispatch_id: dispatch_id}} =
             CloudEventsAsync.fetch_async_result(dispatch, [])

    assert dispatch_id == dispatch.dispatch_id

    terminal = %{schema_version: "v1", request_id: "req-123", status: :ok, output: %{scores: [0.9]}}

    assert {:ok, %{status: :ok, result: ^terminal}} =
             CloudEventsAsync.fetch_async_result(dispatch.dispatch_id, stub_terminal_result: terminal)
  end

  test "async adapter rejects sync operations with typed deterministic error" do
    assert {:error, %{code: :ai_transport_mode_unsupported, category: :capability}} =
             CloudEventsAsync.invoke_sync(@request, [])
  end
end
