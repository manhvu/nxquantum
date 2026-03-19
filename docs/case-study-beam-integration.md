# Case Study: BEAM-Native QML Service Path

## Context

A team already running Elixir/Nx services evaluated whether quantum estimation and kernel workloads could stay inside the same BEAM deployment model instead of adding a separate Python service tier.

## Workflow

1. Circuit estimation and sampling via `Estimator` and `Sampler`.
2. Batch-heavy workflows profiled with Phase 7 benchmark matrix.
3. CI regression gates enabled for throughput-sensitive paths.

Reproducible command:

```bash
NXQ_ENABLE_EXLA=0 NXQ_ENABLE_TORCHX=0 mise exec -- mix run bench/milestone_g.exs
```

## Evidence Snapshot

From `bench/milestone_g_baseline.md`:

1. `:cpu_portable` throughput improved from `1333.333 ops/s` (`batch=8`) to `3030.303 ops/s` (`batch=32`).
2. `:cpu_compiled` throughput improved from `1666.667 ops/s` (`batch=8`) to `3787.879 ops/s` (`batch=32`).
3. Memory metrics remained explicit per batch size in the benchmark report.

## Why It Helped

1. Deterministic contracts simplified CI checks and regression triage.
2. No cross-language RPC boundary was needed for core QML primitives.
3. Runtime profile + fallback contracts made behavior explicit under changing environments.

## Honest Boundaries

1. Provider-specific hardware breadth is still less mature than Python-first ecosystems.
2. Teams needing immediate broad hardware APIs may still keep a hybrid architecture.
