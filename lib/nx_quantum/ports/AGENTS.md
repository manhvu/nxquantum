# Ports Layer Agent Rules

## Scope
`lib/nx_quantum/ports/**`

## Local Rules
- Ports define stable behavior contracts and boundary structs.
- Keep contracts implementation-agnostic and provider-neutral.
- Do not embed adapter logic, retries, transport, or telemetry side effects.
- Version contract changes and update dependent tests/docs in the same change.

## Required Checks
- `mix test.arch`
- provider/contract tests affected by port changes

## Stop If
- port modules include concrete adapter branching
- contract changes are not paired with verification updates
