Feature: Migration assurance workflows

  Rule: Migration promotion decisions are deterministic and evidence-driven
    Scenario: Manifest contracts are canonical and reproducible
      Given migration assurance workflows require canonical manifest generation
      When migration manifests are produced for equivalent workflow inputs
      Then manifest fingerprints stay stable for identical workflow provider target runtime profile and seed inputs
      And manifest payloads include workflow provider target runtime_profile seed and dataset_hash fields
      And manifest serialization remains deterministic across repeated runs
      And all roadmap expectations for this feature are implementation-ready

    Scenario Outline: Gate decision <decision> is a typed first-class contract
      Given migration gate decision <decision> is part of shadow-mode promotion workflows
      When migration comparisons are evaluated for <decision> outcomes
      Then gate decisions emit deterministic <decision> outcomes with typed reason codes
      And decision payloads include tolerance_budget_id comparison_summary and blocking_metric identifiers
      And CI promotion checks treat <decision> as a first-class typed result
      And all roadmap expectations for this feature are implementation-ready

      Examples:
        | decision |
        | promote  |
        | hold     |
        | rollback |

    Scenario: Comparison and reporting contracts stay machine-readable and linked
      Given migration comparison and reporting outputs must be CI-ingestable
      When migration reports are exported
      Then comparison outputs include tolerance_budget_id observed_delta allowed_delta and pass_fail fields per metric
      And migration report exports include schema_version manifest_fingerprint comparison_summary and gate_decision fields
      And migration evidence links provider lifecycle correlation_id and observability trace_id without contract drift
      And all roadmap expectations for this feature are implementation-ready
