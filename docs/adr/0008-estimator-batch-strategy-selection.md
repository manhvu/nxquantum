# ADR 0008: Estimator Batch Strategy Selection and Execution Policy

- Status: Accepted
- Date: 2026-03-23

## Context

`NxQuantum.Estimator.Batch` must support both:

1. deterministic multi-observable execution (single state evolution reused across observables),
2. stochastic/noise execution paths that preserve seeded and typed behavior contracts.

The initial implementation mixed policy checks, strategy selection, and execution details in one module, which increased orchestration complexity and duplicated option semantics with `NxQuantum.Estimator.Scalar`.

## Decision

Refactor estimator batch execution using explicit policy and strategy modules inside the Primitive Estimation context:

1. Introduce `NxQuantum.Estimator.ExecutionMode` as a policy object that classifies options as `:deterministic` or `:stochastic`.
2. Introduce `NxQuantum.Estimator.Batch.Strategy` behavior and concrete strategy modules:
   - `NxQuantum.Estimator.Batch.Strategies.Deterministic`
   - `NxQuantum.Estimator.Batch.Strategies.ScalarFallback`
3. Introduce `NxQuantum.Estimator.ResultBuilder` for shared typed result construction.
4. Keep runtime profile resolution in `NxQuantum.Estimator.RuntimeProfile` and reuse it in scalar and deterministic batch paths.

## Consequences

Positive:

1. Clear single-responsibility boundaries in estimator internals.
2. Easier extension for new execution modes/strategies without changing the public API.
3. Centralized stochastic/deterministic semantics across batch and scalar flows.

Negative:

1. More internal modules to maintain.
2. Slight increase in indirection for readers new to the codebase.

## Follow-up

1. Keep strategy modules internal and public API contracts unchanged.
2. Add benchmark evidence per strategy-sensitive changes.
3. Reuse `ExecutionMode` policy for future estimator/sampler orchestration decisions where relevant.
