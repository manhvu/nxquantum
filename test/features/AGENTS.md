# Feature Test Agent Rules

## Scope
`test/features/**` and supporting `features/*.feature` behavior updates.

## Local Rules
- Scenarios must be deterministic, measurable, and behavior-first.
- Use explicit expected values/tolerances; avoid vague assertions.
- Keep steps focused on observable behavior, not internals.
- No uncontrolled network/provider dependencies in default acceptance runs.

## Required Checks
- `mix test.features`
- targeted `mix test.unit`/`mix test.property` for covered invariants

## Stop If
- acceptance behavior cannot be validated deterministically
- scenario intent is not mapped to a bounded context
