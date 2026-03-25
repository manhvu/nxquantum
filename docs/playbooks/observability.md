# Observability Playbook

## Use When
Adding or changing traces, metrics, logs, observability profiles, or redaction behavior.

## Required Reading
- `docs/observability.md`
- `docs/observability-dashboards.md`
- `docs/adr/0006-opentelemetry-observability-standard.md`

## Flow
1. Update behavior scenarios in `features/provider_observability.feature`.
2. Add failing step mappings in `test/features/steps/provider_observability_steps.ex`.
3. Add failing schema tests for:
   - span names and required attributes
   - metric shape/cardinality
   - log redaction constraints
4. Builder: implement minimal instrumentation change.
5. Critic: verify no data leakage, no architecture boundary violations.
6. Verifier: run `mix test.features`, `mix test.unit`, `mix test.arch`.
7. Update docs and dashboard references.

## Stop Conditions
- redaction or privacy constraints are undefined
- profile behavior (`high_level`, `granular`, `forensics`) is not deterministically testable
- telemetry payload contracts are undocumented
