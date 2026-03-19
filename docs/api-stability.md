# API Stability (v0.2)

This document declares stable vs experimental API surfaces for v0.2.

## Stable Surface (v0.2)

These modules/functions are expected to remain contract-stable through v0.2:

1. `NxQuantum.Circuit.new/1`
2. `NxQuantum.Circuit.bind/2`
3. `NxQuantum.Circuit.expectation/2`
4. `NxQuantum.Gates` pipe-friendly gate constructors (`h`, `x`, `y`, `z`, `rx`, `ry`, `rz`, `cnot`)
5. `NxQuantum.Runtime.supported_profiles/0`
6. `NxQuantum.Runtime.profile!/1`
7. `NxQuantum.Runtime.resolve/2`
8. `NxQuantum.Estimator.expectation/2`
9. `NxQuantum.Estimator.expectation_result/2`
10. `NxQuantum.Estimator.run/2`

## Experimental Surface (v0.2)

These are available but may evolve during v0.2:

1. `NxQuantum.Grad.value_and_grad/3`
2. `NxQuantum.Compiler.optimize/2`
3. `NxQuantum.Kernels.matrix/2`

## Contract Policy

1. Stable API contract changes require:
   - docs update,
   - explicit acceptance mapping,
   - compatibility/migration note in release notes.
2. Experimental APIs may evolve, but must keep deterministic typed error behavior.
3. Public API contract tests live in:
   - `test/nx_quantum/public_api_contract_test.exs`
