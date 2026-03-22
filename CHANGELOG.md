# Changelog

## [0.5.0] - 2026-03-22

### Added

- Top-3 provider bridges for `IBM Runtime`, `AWS Braket`, and `Azure Quantum` with typed lifecycle contracts.
- Cross-provider capability preflight and normalized error taxonomy.
- OpenTelemetry observability profiles (`high_level`, `granular`, `forensics`) plus deterministic fingerprint and portability telemetry contracts.
- Provider migration packs, support tiers, and reproducible provider benchmark matrix for v0.5 release evidence.

### Improved

- State-vector execution planning and hot-path performance, including real-only fast path for compatible `:pauli_z` workflows.
- Deep-circuit benchmark latency (`deep_6q`) with new planning and evolution optimizations.

### Docs

- v0.5 feature spec, acceptance criteria, provider implementation plan, migration packs, benchmark matrix, and observability guides finalized.

### References

- [docs/v0.5-feature-spec.md](docs/v0.5-feature-spec.md)
- [docs/v0.5-acceptance-criteria.md](docs/v0.5-acceptance-criteria.md)
- [docs/v0.5-provider-implementation-plan.md](docs/v0.5-provider-implementation-plan.md)
- [docs/v0.5-migration-packs.md](docs/v0.5-migration-packs.md)
- [docs/v0.5-benchmark-matrix.md](docs/v0.5-benchmark-matrix.md)
- [docs/v0.5-provider-support-tiers.md](docs/v0.5-provider-support-tiers.md)
