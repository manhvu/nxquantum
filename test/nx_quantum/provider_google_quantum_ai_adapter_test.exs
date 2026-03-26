defmodule NxQuantum.ProviderGoogleQuantumAIAdapterTest do
  use ExUnit.Case, async: true

  alias NxQuantum.Adapters.Providers.GoogleQuantumAI
  alias NxQuantum.ProviderBridge

  test "google quantum ai adapter normalizes lifecycle operations" do
    payload = %{workflow: :sampler, shots: 512}

    opts = [
      target: "projects/example/locations/us-central1/processors/rainbow",
      provider_config: %{
        auth_token: "token",
        project_id: "example",
        location: "us-central1",
        processor_id: "projects/example/locations/us-central1/processors/rainbow"
      }
    ]

    assert {:ok, submitted} = ProviderBridge.submit_job(GoogleQuantumAI, payload, opts)
    assert submitted.state == :submitted
    assert submitted.metadata.transport.mode == :fixture

    assert {:ok, polled} = ProviderBridge.poll_job(GoogleQuantumAI, submitted, opts)
    assert polled.state == :completed

    assert {:ok, cancelled} = ProviderBridge.cancel_job(GoogleQuantumAI, submitted, opts)
    assert cancelled.state == :cancelled

    assert {:ok, result} = ProviderBridge.fetch_result(GoogleQuantumAI, polled, opts)
    assert result.state == :completed
    assert result.provider == :google_quantum_ai
    assert result.metadata.transport.mode == :fixture
  end

  test "google quantum ai missing config maps to auth error with deterministic redaction" do
    assert {:error, %{code: :provider_auth_error, metadata: %{provider_config: redacted}}} =
             ProviderBridge.submit_job(GoogleQuantumAI, %{workflow: :sampler},
               target: "projects/example/locations/us-central1/processors/rainbow",
               provider_config: %{auth_token: "secret-google-token", project_id: "example", location: "us-central1"}
             )

    assert redacted.auth_token == "[REDACTED]"
  end
end
