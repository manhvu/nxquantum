# Release Process

## Goals

1. Keep release quality gates identical to CI quality gates.
2. Ensure package and docs artifacts are built deterministically before publish.
3. Keep release steps explicit and auditable.

## Pre-Release Checklist

1. `mix quality`
2. `mix dialyzer`
3. `mix docs.build`
4. `mix hex.build`
5. Update roadmap/spec status and release notes summary.

## CI Release Automation

The repository includes:

1. `.github/workflows/ci.yml` for matrix quality/testing lanes.
2. `.github/workflows/release.yml` for release dry-run on tags/manual dispatch.

`release.yml` performs:

1. dependency install and compile,
2. `mix ci`,
3. `mix hex.build`,
4. `mix docs.build`,
5. artifact upload for package tarball and generated docs.

## Publishing

Use the repository publishing flow:

1. `mix hex.publish`
2. `mix hex.publish docs`

Dry-run before publish:

1. `mix hex.publish --dry-run`
