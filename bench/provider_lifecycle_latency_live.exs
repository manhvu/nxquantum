alias NxQuantum.Adapters.Providers.IBMRuntime
alias NxQuantum.ProviderBridge

lane = List.first(System.argv()) || "live_smoke"
transport_mode = if lane == "live", do: :live, else: :live_smoke
iterations = (List.last(System.argv()) || "20") |> String.to_integer()

if transport_mode == :live do
  System.put_env("NXQ_PROVIDER_LIVE", "true")
else
  System.put_env("NXQ_PROVIDER_LIVE_SMOKE", "true")
end

opts = [
  transport_mode: transport_mode,
  target: "ibm_backend_simulator",
  provider_config: %{auth_token: "token", channel: "ibm_cloud", backend: "ibm_backend_simulator"},
  live_responses: %{
    submit: %{"raw_state" => "SUBMITTED", "provider_job_id" => "ibm_live_job"},
    poll: %{"raw_state" => "COMPLETED"},
    cancel: %{"raw_state" => "CANCELLED"},
    fetch_result: %{"raw_state" => "COMPLETED", "payload" => %{"workflow" => "sampler", "counts" => %{"00" => 64, "11" => 64}}}
  }
]

phase_metrics =
  for phase <- [:submit, :poll, :cancel, :fetch_result], into: %{} do
    {time_us, _} =
      :timer.tc(fn ->
        Enum.each(1..iterations, fn _ ->
          {:ok, submitted} = ProviderBridge.submit_job(IBMRuntime, %{workflow: :sampler, shots: 128}, opts)

          case phase do
            :submit ->
              :ok

            :poll ->
              {:ok, _} = ProviderBridge.poll_job(IBMRuntime, submitted, opts)

            :cancel ->
              {:ok, _} = ProviderBridge.cancel_job(IBMRuntime, submitted, opts)

            :fetch_result ->
              {:ok, polled} = ProviderBridge.poll_job(IBMRuntime, submitted, opts)
              {:ok, _} = ProviderBridge.fetch_result(IBMRuntime, polled, opts)
          end
        end)
      end)

    {phase, Float.round(time_us / 1000.0 / iterations, 6)}
  end

IO.puts(
  "NXQ_PROVIDER_LATENCY lane=#{lane} provider=ibm_runtime target=ibm_backend_simulator credential_policy=env_gated phases=#{inspect(phase_metrics)}"
)
