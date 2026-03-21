Feature: Provider capability contracts

  Rule: Capability envelope is explicit and stable
    Scenario: Required capability keys are defined for every top-3 provider
      Given provider capability contract version "v1" for top-3 providers
      When I validate required capability keys for each provider
      Then each capability envelope includes all required capability keys
      | key                           |
      | supports_estimator            |
      | supports_sampler              |
      | supports_batch                |
      | supports_dynamic              |
      | supports_cancel_in_running    |
      | supports_calibration_payload  |
      | target_class                  |
      And capability schema versioning is explicit and deterministic

  Rule: Capability preflight rejects unsupported requests
    Scenario: Unsupported dynamic request fails before remote submission
      Given provider "aws_braket" does not support dynamic execution for selected target
      When I submit a dynamic workflow request
      Then error "provider_capability_mismatch" is returned
      And error metadata includes provider "aws_braket" and the missing capability
      And no remote submission is attempted

  Rule: Capability checks preserve deterministic behavior
    Scenario: Equivalent inputs produce equivalent preflight outcomes
      Given identical capability contracts and identical workflow request input
      When I run preflight validation twice
      Then both preflight outcomes are identical
      And unknown capability states map to error "provider_invalid_response"

  Rule: Error taxonomy is unified across providers
    Scenario: Capability mismatch uses a consistent clean taxonomy
      Given capability preflight is evaluated for IBM Runtime, AWS Braket, and Azure Quantum
      When each provider rejects an unsupported capability for the selected target
      Then error "provider_capability_mismatch" is returned consistently
      And error metadata includes provider, target, and capability identifiers

    Scenario: Unexpected provider response shape maps to invalid response taxonomy
      Given a provider adapter returns an unexpected callback response shape
      When response normalization is applied
      Then error "provider_invalid_response" is returned
      And provider-specific raw diagnostics are preserved under metadata
