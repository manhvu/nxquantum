# Provider Contracts Playbook

## Use When
Implementing or evolving provider lifecycle, capability, error envelope, or interoperability contracts.

## Required Reading
- `docs/migration-python-playbook.md`
- `docs/python-comparison-workflows.md`
- `docs/standalone-integration-profiles.md`
- `docs/architecture.md`
- `docs/adr/0002-provider-capability-contract-v1.md`

## Flow
1. Define/update machine-readable contract expectations first.
2. Add failing acceptance scenarios in `features/` and step mappings in `test/features/steps/`.
3. Add failing contract/unit/property tests for lifecycle transitions, errors, and capability payloads.
4. Builder: implement minimal adapter-side change behind existing ports.
5. Critic: ensure no provider-specific payload leaks into domain/application contracts.
6. Verifier: run `mix test.features`, `mix test.unit`, `mix test.property`, `mix test.provider_smoke`, `mix test.arch`.
7. Update migration and interoperability docs.

## Stop Conditions
- contract versions are missing or ambiguous
- interoperability behavior cannot be validated without uncontrolled external dependencies
- lifecycle transitions lack typed error coverage
