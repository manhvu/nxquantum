# Simulator Adapter Agent Rules

## Scope
`lib/nx_quantum/adapters/simulators/**`

## Local Rules
- Isolate simulator/provider-specific implementation details here.
- Implement ports without changing domain/application contracts.
- Map backend/runtime failures into typed boundary errors.
- Keep stochastic behavior controllable through explicit seeds/options.

## Required Checks
- affected unit/property suites
- `mix test.arch`
- benchmark evidence for non-trivial performance changes

## Stop If
- adapter details leak outside adapter boundaries
- failure mapping is ambiguous or untyped
