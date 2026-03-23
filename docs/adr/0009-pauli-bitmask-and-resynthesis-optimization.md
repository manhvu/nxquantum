# ADR 0009: Pauli Bitmask Evaluation, Sparse-Pauli Representation, and 1Q Re-synthesis

- Status: Accepted
- Date: 2026-03-23

## Context

NxQuantum needs stronger performance-oriented internals for:

1. multi-observable expectation evaluation,
2. sampled expectation post-processing from count distributions,
3. compact Pauli operator representation with conversion paths,
4. single-qubit run simplification in compiler optimization.

Qiskit reference paths indicate clear value in:

1. bitmask-based Pauli expectation kernels,
2. sparse-term and lookup-table sampled expectation evaluation,
3. compressed sparse-Pauli modeling with efficient materialization,
4. cost/error-aware 1q re-synthesis passes.

## Decision

Adopt additive internal optimizations in bounded contexts:

1. Add bitmask-based Pauli expectation path in state-vector adapter internals with thresholded parallel observable evaluation.
2. Add `NxQuantum.Observables.SparsePauli` compressed term model with dense and CSR generation APIs and thresholded parallel generation.
3. Add sampled expectation utility (`NxQuantum.Estimator.SampledExpval`) with lookup-table path over count distributions and sparse-diagonal operator support.
4. Add compiler pass `NxQuantum.Compiler.Passes.Resynthesize1Q` with cost/error-aware replacement of contiguous 1q runs.

Public API remains stable; additive public helper exposure is limited to:

- `NxQuantum.Estimator.sampled_expectation_from_counts/2`

## Consequences

Positive:

1. Better scaling for high observable-count deterministic estimator requests.
2. Cleaner post-processing path for sampled expectation on diagonal Pauli operators.
3. Explicit sparse operator substrate for future estimator/transpiler work.
4. Lower gate counts from 1q run re-synthesis when replacement is beneficial and numerically safe.

Negative:

1. More internal modules and tuning knobs to maintain.
2. Sampled count-path remains limited to diagonal/reals unless richer measurement metadata is introduced.

## Follow-up

1. Add benchmark evidence and CI checks for deterministic observable-batch paths.
2. Extend sparse-Pauli interoperability to additional primitives as needed.
3. Expand re-synthesis candidate families if future cost models require broader basis targeting.
