# Livebook-First Tutorials

Runnable notebooks are provided under `examples/livebook/`.

## Prerequisites

1. `livebook` installed and available in your shell.
2. Repo dependencies installed (`mise install`, `mix setup`).

## Available Tutorials

1. `examples/livebook/estimator_sampler_walkthrough.livemd`
2. `examples/livebook/kernel_and_transpiler_walkthrough.livemd`
3. `examples/livebook/provider_bridge_side_by_side.livemd`

## How To Run

```bash
livebook server
```

Then open:

1. `examples/livebook/estimator_sampler_walkthrough.livemd`
2. `examples/livebook/kernel_and_transpiler_walkthrough.livemd`
3. `examples/livebook/provider_bridge_side_by_side.livemd`

Both notebooks use `Mix.install(path: "../..")` so they resolve NxQuantum from this repository checkout.

## Tutorial Goals

1. Show deterministic estimator and sampler usage with fixed seeds.
2. Demonstrate kernel generation with sample tensor inputs.
3. Demonstrate topology-aware transpilation and report metadata.
4. Demonstrate side-by-side provider lifecycle parity (`IBM Runtime`, `AWS Braket`, `Azure Quantum`) in fixture mode.
