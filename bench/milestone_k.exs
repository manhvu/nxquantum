alias NxQuantum.Adapters.Providers.AwsBraket
alias NxQuantum.Adapters.Providers.AzureQuantum
alias NxQuantum.Adapters.Providers.IBMRuntime
alias NxQuantum.ProviderBridge

providers = [
  {:ibm_runtime, IBMRuntime,
   [
     target: "ibm_backend_simulator",
     provider_config: %{auth_token: "ibm-token", channel: "ibm_cloud", backend: "ibm_backend_simulator"}
   ]},
  {:aws_braket, AwsBraket,
   [
     target: "arn:aws:braket:::device/quantum-simulator/amazon/sv1",
     provider_config: %{
       region: "us-east-1",
       credentials_profile: "default",
       device_arn: "arn:aws:braket:::device/quantum-simulator/amazon/sv1"
     }
   ]},
  {:azure_quantum, AzureQuantum,
   [
     target: "azure.quantum.sim",
     provider_config: %{
       workspace: "ws-1",
       auth_context: "managed_identity",
       target_id: "azure.quantum.sim",
       provider_name: "microsoft"
     }
   ]}
]

iterations = 30
payload = %{workflow: :sampler, shots: 1024}

measure_ms = fn fun ->
  {microseconds, result} = :timer.tc(fun)
  {Float.round(microseconds / 1000.0, 3), result}
end

stats =
  Map.new(providers, fn {provider_id, adapter, adapter_opts} ->
    measurements =
      for _ <- 1..iterations do
        {latency_ms, result} = measure_ms.(fn -> ProviderBridge.run_lifecycle(adapter, payload, adapter_opts) end)
        %{latency_ms: latency_ms, result: result}
      end

    successes = Enum.count(measurements, fn m -> match?({:ok, _}, m.result) end)
    failures = iterations - successes

    latencies = Enum.map(measurements, & &1.latency_ms) |> Enum.sort()
    mean = Enum.sum(latencies) / max(length(latencies), 1)
    p95_index = max(0, trunc(Float.ceil(length(latencies) * 0.95)) - 1)
    p95 = Enum.at(latencies, p95_index, 0.0)

    {provider_id,
     %{
       mean_latency_ms: Float.round(mean, 3),
       p95_latency_ms: Float.round(p95, 3),
       success_count: successes,
       failure_count: failures
     }}
  end)

IO.puts("NxQuantum Milestone K provider benchmark matrix (fixture deterministic lane)")
IO.puts("workflow=:sampler shots=1024 iterations=#{iterations} runtime_profile=:cpu_portable")

Enum.each([:ibm_runtime, :aws_braket, :azure_quantum], fn provider_id ->
  row = Map.fetch!(stats, provider_id)

  IO.puts(
    "provider=#{provider_id} mean_latency_ms=#{row.mean_latency_ms} p95_latency_ms=#{row.p95_latency_ms} " <>
      "success_count=#{row.success_count} failure_count=#{row.failure_count}"
  )
end)
