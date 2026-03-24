defmodule NxQuantum.ProviderLifecycleLatencyGuardTest do
  use ExUnit.Case, async: true

  @fixture_script Path.expand("../../bench/provider_lifecycle_latency_fixture.exs", __DIR__)
  @live_script Path.expand("../../bench/provider_lifecycle_latency_live.exs", __DIR__)

  test "provider lifecycle latency scripts exist for fixture and live lanes" do
    assert File.exists?(@fixture_script)
    assert File.exists?(@live_script)
  end

  test "scripts cover submit poll cancel and fetch_result phases" do
    fixture = File.read!(@fixture_script)
    live = File.read!(@live_script)

    for phase <- ["submit", "poll", "cancel", "fetch_result"] do
      assert fixture =~ phase
      assert live =~ phase
    end
  end
end
