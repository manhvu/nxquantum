Feature: AWS Braket provider bridge

  Rule: Braket task lifecycle is normalized
    Scenario: Task submit/get/cancel/fetch_result paths map to typed lifecycle
      Given AWS Braket provider integration is configured for a gate-model target
      When I execute submit, poll, cancel, and fetch_result operations
      Then Braket task states are normalized into NxQuantum lifecycle states
      And terminal states include typed metadata with provider context
      And unknown status payloads return error "provider_invalid_response"

  Rule: Target and device constraints are explicit
    Scenario: Unsupported target class is rejected by capability preflight
      Given selected Braket target class is unsupported for requested workflow
      When I run capability preflight
      Then error "provider_capability_mismatch" is returned
      And error metadata includes provider and target identifiers
      And no fallback target is selected automatically

  Rule: Workflow capability boundaries are explicit and forward-compatible
    Scenario: Unsupported workflow classes are rejected deterministically with upgrade-safe contracts
      Given Braket adapter capability profile is explicitly declared
      When an unsupported workflow class is submitted
      Then the request is rejected deterministically
      And typed diagnostics explain the unsupported workflow class
      And capability metadata indicates how support can be introduced without breaking existing contracts

  Rule: Failure handling remains deterministic across lifecycle operations
    Scenario: Fetch result before terminal completion returns invalid state
      Given an AWS Braket task is in non-terminal state "submitted"
      When fetch_result is requested
      Then error "provider_invalid_state" is returned
      And error metadata includes operation "fetch_result" and current task state

    Scenario: Poll timeout maps to transport error with operation context
      Given an AWS Braket poll operation reaches a transport timeout
      When poll is requested
      Then error "provider_transport_error" is returned
      And error metadata includes operation "poll" and provider identifier

    Scenario: Unexpected callback payload maps to invalid response
      Given AWS Braket adapter returns an unexpected payload for submit
      When response normalization is applied
      Then error "provider_invalid_response" is returned
      And diagnostics include operation "submit"
