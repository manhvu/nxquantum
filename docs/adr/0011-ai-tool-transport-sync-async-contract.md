# ADR 0011: AI Tool Transport Port with Sync and Async Adapter Profiles

Date: 2026-03-23
Status: Accepted

## Context

Phase 19 introduced `NxQuantum.AI` contract work and a standards baseline that combines MCP/JSON-RPC, JSON Schema/OpenAPI, OpenTelemetry, and optional CloudEvents.

We still need an explicit architecture decision for how these standards map to implementation boundaries.

Without a transport-focused port:

1. Tool execution orchestration risks coupling directly to one protocol (for example MCP only).
2. Async delivery requirements (queue/event-driven workflows) would leak into domain/application code.
3. Future transport expansion would increase migration cost and break deterministic contract behavior.

NxQuantum already uses DDD + Hexagonal boundaries in provider and observability slices. AI tooling must follow the same strategy.

## Decision

Adopt a dual-mode transport contract behind a single hexagonal port.

1. Introduce `NxQuantum.Ports.AIToolTransport` as the canonical transport boundary.
2. Standardize two execution models under that port:
   - sync request/response (`invoke_sync/2`)
   - async dispatch/result lifecycle (`publish_async/2`, `fetch_async_result/2`, `cancel_async/2`)
3. Keep one canonical NxQuantum envelope model (`request`, `result`, `error`) independent of transport wire format.
4. Implement two initial adapters:
   - `NxQuantum.Adapters.AIToolTransport.McpJsonRpcSync` for MCP/JSON-RPC sync calls.
   - `NxQuantum.Adapters.AIToolTransport.CloudEventsAsync` for CloudEvents async dispatch.
5. Enforce capability-driven execution behavior:
   - adapters declare supported modes via `capabilities/1`
   - unsupported mode calls return typed deterministic errors (no silent fallback)
6. Preserve observability parity across both models:
   - trace and correlation metadata must propagate through both sync and async flows
   - async dispatch/result linkage must remain queryable by `request_id` and `correlation_id`

## Consequences

Positive:

1. Transport flexibility without contract fragmentation.
2. Clean migration path for teams that need low-latency sync and queue-based async in the same platform.
3. Better blue-ocean product posture: deterministic typed contracts + BEAM reliability + transport neutrality.
4. Reduced long-term implementation risk when adding new hosts/brokers.

Tradeoffs:

1. More upfront interface design and contract tests.
2. Additional adapter scaffolding before full production transport integration.

## Contract Impact

1. Public user-facing quantum primitives remain unchanged.
2. New transport port is additive and internal-facing for `NxQuantum.AI` integration slices.
3. Any change to sync/async envelope shape requires explicit contract versioning and migration notes.

## Implementation Notes

1. Phase 19 includes the new port and scaffold adapters.
2. Full production transport behavior (broker wiring, retries, dead-letter policy, delivery semantics) is staged in follow-up milestones.
3. Contract tests must verify deterministic typed failures for unsupported mode operations.

## References

1. MCP specification: https://modelcontextprotocol.io/specification/2024-11-05/index
2. JSON-RPC 2.0: https://www.jsonrpc.org/specification
3. CloudEvents 1.0: https://cloudevents.io/
4. W3C Trace Context: https://www.w3.org/TR/trace-context/
