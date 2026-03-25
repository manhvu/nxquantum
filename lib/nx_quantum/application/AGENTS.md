# Application Layer Agent Rules

## Scope
`lib/nx_quantum/application/**`

## Local Rules
- Keep this layer as orchestration of use cases and policies.
- Depend on domain abstractions and ports only.
- Do not call provider SDKs, adapter modules, or transport details directly.
- Keep error surfaces typed and deterministic.

## Required Checks
- `mix test.arch`
- relevant acceptance/unit suites for touched use cases

## Stop If
- any adapter/provider payload type appears in public application contracts
- orchestration code starts carrying infrastructure concerns
