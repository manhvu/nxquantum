Feature: Provider mitigation and calibration contracts

  Rule: Calibration payload provenance is normalized
    Scenario: Provider calibration payload is normalized into typed schema
      Given a provider calibration payload is available for the selected target
      When calibration normalization is applied
      Then mitigation pipeline accepts a typed calibration schema
      And calibration metadata includes schema version deterministically
      And calibration metadata includes source and provenance fields deterministically

  Rule: Malformed calibration payloads fail with typed diagnostics
    Scenario: Malformed calibration payload returns typed error taxonomy and shape diagnostics
      Given a malformed provider calibration payload is submitted
      When calibration normalization is applied
      Then error "provider_invalid_response" is returned
      And shape diagnostics include expected and actual tensor dimensions
      And raw payload diagnostics are preserved under metadata with deterministic redaction

  Rule: Mitigation pipeline contracts stay deterministic
    Scenario: Mitigation pipeline emits typed output schema and applied-step provenance
      Given normalized calibration data and mitigation strategy configuration are provided
      When mitigation pipeline runs on provider result tensors
      Then mitigated outputs follow a deterministic typed schema
      And mitigation metadata includes applied steps, parameters, and calibration reference
      And skipped mitigation steps are explicit in metadata
