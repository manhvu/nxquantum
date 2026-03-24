defmodule NxQuantum.ProviderReplayFixtureTest do
  use ExUnit.Case, async: true

  alias NxQuantum.Adapters.Providers.IBMRuntime
  alias NxQuantum.ProviderBridge
  alias NxQuantum.ProviderBridge.ReplayFixture

  test "capture/1 builds deterministic fixture envelope from lifecycle data" do
    opts = [
      target: "ibm_backend_simulator",
      provider_config: %{auth_token: "token", channel: "ibm_cloud", backend: "ibm_backend_simulator"}
    ]

    assert {:ok, run} = ProviderBridge.run_lifecycle(IBMRuntime, %{workflow: :sampler, shots: 64}, opts)
    assert {:ok, fixture} = ReplayFixture.capture(run)

    assert fixture.schema_version == :v1
    assert fixture.provider == :ibm_runtime
    assert fixture.submit.id == run.submitted.id
    assert fixture.poll.id == run.polled.id
    assert fixture.fetch_result.job_id == run.result.job_id
    assert is_binary(fixture.request_id)
    assert is_binary(fixture.correlation_id)
    assert is_binary(fixture.idempotency_key)
  end

  test "capture/1 returns typed error for invalid input" do
    assert {:error, %{code: :invalid_replay_fixture_input}} = ReplayFixture.capture(%{submitted: :bad})
  end
end
