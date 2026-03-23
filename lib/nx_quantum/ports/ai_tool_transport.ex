defmodule NxQuantum.Ports.AIToolTransport do
  @moduledoc """
  Port for AI tool transport adapters.

  The contract supports both low-latency sync request/response flows and
  asynchronous dispatch/result workflows.
  """

  @type transport_id :: atom() | String.t() | module()
  @type transport_mode :: :sync | :async

  @type capabilities :: %{
          required(:modes) => [transport_mode()],
          optional(:protocol) => atom() | String.t(),
          optional(:spec_version) => String.t(),
          optional(:metadata) => map()
        }

  @type request_envelope :: map()
  @type result_envelope :: map()

  @type dispatch_ref ::
          String.t()
          | %{
              required(:dispatch_id) => String.t(),
              optional(:request_id) => String.t() | nil,
              optional(:correlation_id) => String.t() | nil,
              optional(:metadata) => map()
            }

  @type async_dispatch :: %{
          required(:dispatch_id) => String.t(),
          required(:status) => :accepted | :queued,
          optional(:request_id) => String.t() | nil,
          optional(:correlation_id) => String.t() | nil,
          optional(:metadata) => map()
        }

  @type async_result :: %{
          required(:dispatch_id) => String.t(),
          required(:status) => :pending | :ok | :error,
          optional(:result) => result_envelope() | nil,
          optional(:error) => transport_error() | nil,
          optional(:metadata) => map()
        }

  @type transport_error_code ::
          :ai_transport_mode_unsupported
          | :ai_transport_not_configured
          | :ai_transport_dispatch_failed
          | :ai_transport_result_unavailable
          | :ai_transport_internal_error

  @type transport_error :: %{
          required(:code) => transport_error_code(),
          required(:category) => :capability | :transport | :timeout | :internal,
          required(:retryable) => boolean(),
          required(:message) => String.t(),
          optional(:details) => map()
        }

  @callback transport_id() :: transport_id()
  @callback capabilities(keyword()) :: capabilities()

  @callback invoke_sync(request_envelope(), keyword()) ::
              {:ok, result_envelope()} | {:error, transport_error()}

  @callback publish_async(request_envelope(), keyword()) ::
              {:ok, async_dispatch()} | {:error, transport_error()}

  @callback fetch_async_result(dispatch_ref(), keyword()) ::
              {:ok, async_result()} | {:error, transport_error()}

  @callback cancel_async(dispatch_ref(), keyword()) ::
              :ok | {:error, transport_error()}

  @optional_callbacks invoke_sync: 2,
                      publish_async: 2,
                      fetch_async_result: 2,
                      cancel_async: 2
end
