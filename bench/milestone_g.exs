alias NxQuantum.Performance

profiles = [:cpu_portable, :cpu_compiled]
batch_sizes = [1, 8, 32, 128]

report_by_profile =
  Map.new(profiles, fn profile ->
    {:ok, report} = Performance.benchmark_matrix(batch_sizes, runtime_profile: profile)
    {profile, report.entries}
  end)

IO.puts("NxQuantum Milestone G deterministic benchmark matrix")

Enum.each(report_by_profile, fn {profile, entries} ->
  IO.puts("\nprofile=#{profile}")

  Enum.each(entries, fn entry ->
    IO.puts(
      "batch=#{entry.batch_size} latency_ms=#{entry.latency_ms} throughput_ops_s=#{entry.throughput_ops_s} memory_mb=#{entry.memory_mb}"
    )
  end)
end)

baseline = %{
  version: "2026.03",
  max_regression_pct: 10.0,
  throughput_by_batch: %{1 => 1333.333, 8 => 1333.333, 32 => 3030.303, 128 => 3030.303}
}

{:ok, gate_eval} =
  Performance.evaluate_gates(baseline, %{entries: Map.fetch!(report_by_profile, :cpu_portable)})

IO.puts("\nperformance_gate_status=#{gate_eval.status}")
