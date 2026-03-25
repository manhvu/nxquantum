# Topology Routing Playbook

## Use When
Changing transpilation and routing behavior (path selection, tie-breaks, strict-mode failure semantics).

## Required Reading
- `docs/architecture.md`
- `docs/bounded-context-map.md`
- `docs/adr/0001-hexagonal-ddd-foundation.md`

## Flow
1. Define/update deterministic behavior in `features/topology_transpilation.feature`.
2. Update `test/features/steps/topology_transpilation_steps.ex`.
3. Add failing unit/property coverage for:
   - shortest-path routing
   - equal-path deterministic tie-break
   - strict-mode typed failures
   - transpilation report contract fields
4. Builder: implement minimal routing change.
5. Critic: verify no provider or adapter leakage into domain/application.
6. Verifier: run `mix test.features`, `mix test.unit`, `mix test.property`, `mix test.arch`.
7. Update docs if contracts or reports changed.

## Stop Conditions
- nondeterministic route tie-break remains
- strict-mode failures are untyped or ambiguous
- routing logic leaks provider-specific semantics
