# Benchmark Agent Rules

## Scope
`bench/**`

## Local Rules
- Benchmarks must be reproducible (fixed seed/workload/runtime profile).
- Keep benchmark scripts focused on one claim per scenario.
- Report before/after deltas with environment notes.
- Never present benchmark gains without matching correctness evidence.

## Required Checks
- benchmark script rerun with consistent settings
- targeted correctness/property tests

## Stop If
- benchmark cannot be reproduced reliably
- performance claim lacks semantic-correctness proof
