# Milestone G Baseline Report

Generated with:

```bash
NXQ_ENABLE_EXLA=0 NXQ_ENABLE_TORCHX=0 mise exec -- mix run bench/milestone_g.exs
```

Reference output snapshot (`2026-03-19`):

## Profile `:cpu_portable`

| Batch | Latency (ms) | Throughput (ops/s) | Memory (MB) |
| --- | --- | --- | --- |
| 1 | 0.75 | 1333.333 | 48.15 |
| 8 | 6.0 | 1333.333 | 49.2 |
| 32 | 10.56 | 3030.303 | 52.8 |
| 128 | 42.24 | 3030.303 | 67.2 |

## Profile `:cpu_compiled`

| Batch | Latency (ms) | Throughput (ops/s) | Memory (MB) |
| --- | --- | --- | --- |
| 1 | 0.6 | 1666.667 | 48.15 |
| 8 | 4.8 | 1666.667 | 49.2 |
| 32 | 8.448 | 3787.879 | 52.8 |
| 128 | 33.792 | 3787.879 | 67.2 |

Performance gate reference:

- Baseline version: `2026.03`
- Threshold: `10%` max throughput regression
- Gate status from reference run: `passed`
