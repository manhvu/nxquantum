# Docs Agent Rules

## Scope
`docs/**`, `README.md`, `SKILLS.md`

## Local Rules
- Keep docs aligned with actual contracts, tests, and architecture.
- Keep specialized procedures in `docs/playbooks/`, not `docs/development-flow.md`.
- Prefer concise, executable guidance over narrative.
- Maintain consistency across roadmap, architecture, bounded-context map, and API docs.

## Required Checks
- `mix docs.build` for substantial doc changes
- manual link/path sanity check for changed docs

## Stop If
- docs conflict with implementation behavior
- commands or file paths are stale or non-executable
