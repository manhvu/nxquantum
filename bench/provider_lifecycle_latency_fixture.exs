alias NxQuantum.Adapters.Providers.IBMRuntime
alias NxQuantum.ProviderBridge

iterations = (List.first(System.argv()) || "100") |> String.to_integer()

opts = [
  transport_mode: :fixture,
  target: "ibm_backend_simulator",
  provider_config: %{auth_token: "token", channel: "ibm_cloud", backend: "ibm_backend_simulator"}
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
  "NXQ_PROVIDER_LATENCY lane=fixture provider=ibm_runtime target=ibm_backend_simulator credential_policy=fixture phases=#{inspect(phase_metrics)}"
)
