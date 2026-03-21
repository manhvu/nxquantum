# Observability Starter Dashboards (v0.5)

This document provides starter dashboard conventions for top-3 provider workflows.

Primary standard references:

1. `docs/observability.md`
2. `docs/adr/0006-opentelemetry-observability-standard.md`

## Dashboard 1: Provider Lifecycle Health

Purpose: track lifecycle reliability for `submit/poll/cancel/fetch_result`.

Panels:

1. Success/failure counters:
   - `nxq.workflow.success.count`
   - `nxq.workflow.failure.count`
2. Provider error rates by code:
   - `nxq.provider.error.count` grouped by `provider,error_code`
3. Lifecycle latency histogram:
   - `nxq.provider.request.latency_ms` grouped by `provider,target,workflow`

## Dashboard 2: Queue vs Execution Behavior

Purpose: separate queue pressure from execution latency.

Panels:

1. Queue wait distribution:
   - `nxq.provider.queue_wait_ms`
2. Execution duration distribution:
   - `nxq.provider.execution_ms`
3. P95 request latency by provider:
   - `nxq.provider.request.latency_ms`

## Dashboard 3: Portability Tracking

Purpose: compare equivalent workloads across providers.

Panels:

1. Portability latency delta:
   - `nxq.portability.latency_delta_ms`
2. Expectation delta:
   - `nxq.portability.expectation_delta_abs`
3. Sampling divergence:
   - `nxq.portability.sample_kl_divergence`

## Label and Cardinality Rules

1. Allowed dimensions:
   - `provider`
   - `target`
   - `workflow`
   - `runtime_profile`
   - `error_code` (when present)
2. Never add raw `job_id` as metric labels.
3. Keep fingerprint values in logs/spans, not metric labels.

## Profile Guidance

1. `high_level`: default production dashboard profile.
2. `granular`: short-term debugging and performance analysis.
3. `forensics`: incident investigation only, time-bounded.

## Validation Checklist

1. Lifecycle spans exist for all top-3 providers.
2. Core metric names/units match observability contract.
3. Structured logs include `trace_id` and `span_id`.
4. Redaction rules prevent credential leakage.
