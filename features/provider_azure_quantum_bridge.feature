Feature: Azure Quantum provider bridge

  Rule: Workspace and target/provider contracts are explicit
    Scenario: Invalid workspace or target/provider selections fail with typed diagnostics
      Given Azure Quantum integration is configured with workspace and target/provider selectors
      When configuration validation fails
      Then a typed configuration error is returned
      And error metadata includes workspace, target, and provider context
      And opaque pass-through configuration failures are not allowed

  Rule: Azure lifecycle maps to normalized states
    Scenario: submit/poll/cancel/fetch_result return deterministic normalized envelopes
      Given Azure Quantum provider lifecycle operations are requested
      When submit, poll, cancel, and fetch_result operations are executed
      Then lifecycle results are returned through normalized NxQuantum envelopes
      And status mapping is deterministic and preserves raw state metadata
      And terminal envelopes remain shape-stable for equivalent requests

  Rule: Cancellation caveats are visible
    Scenario: Provider-specific cancellation behavior is surfaced explicitly
      Given selected Azure provider/target has cancellation caveats
      When cancellation is requested for a running job
      Then caveat metadata is included in typed result context
      And cancellation semantics are explicit and not hidden
      And provider/target mismatch failures map to capability errors

  Rule: Failure handling remains deterministic across lifecycle operations
    Scenario: Fetch result before terminal completion returns invalid state
      Given an Azure Quantum job is in non-terminal state "submitted"
      When fetch_result is requested
      Then error "provider_invalid_state" is returned
      And error metadata includes operation "fetch_result" and current job state

    Scenario: Poll timeout maps to transport error with operation context
      Given an Azure Quantum poll operation reaches a transport timeout
      When poll is requested
      Then error "provider_transport_error" is returned
      And error metadata includes operation "poll" and provider identifier

    Scenario: Unexpected callback payload maps to invalid response
      Given Azure Quantum adapter returns an unexpected payload for submit
      When response normalization is applied
      Then error "provider_invalid_response" is returned
      And diagnostics include operation "submit"
