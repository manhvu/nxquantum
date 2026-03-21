Feature: IBM Runtime provider bridge

  Rule: IBM lifecycle follows typed bridge contract
    Scenario: submit/poll/cancel/fetch_result are normalized to NxQuantum lifecycle states
      Given IBM Runtime provider integration is configured
      When I execute submit, poll, cancel, and fetch_result lifecycle operations
      Then lifecycle operations are exposed through ProviderBridge contract
      And IBM lifecycle states are normalized deterministically
      And raw provider states are preserved under metadata

  Rule: Primitive-centric workflows are first-class
    Scenario: Estimator and sampler intents are supported by contract
      Given IBM Runtime supports estimator and sampler workflow intents
      When I submit estimator and sampler workflow requests
      Then requests are validated against typed capability contract
      And unsupported capability requests fail fast with typed errors
      And result payloads preserve typed shape guarantees

  Rule: Error mapping is deterministic and secure
    Scenario: Auth, backend, and runtime failures map to stable error taxonomy
      Given an IBM Runtime lifecycle operation fails with auth or backend error
      When error mapping is applied
      Then a typed provider error code is returned
      And error metadata includes provider and operation context
      And sensitive fields are deterministically redacted

    Scenario: Fetch result before terminal completion returns invalid state
      Given an IBM Runtime job is in non-terminal state "submitted"
      When fetch_result is requested
      Then error "provider_invalid_state" is returned
      And error metadata includes operation "fetch_result" and current job state

    Scenario: Poll timeout maps to transport error with operation context
      Given an IBM Runtime poll operation reaches a transport timeout
      When poll is requested
      Then error "provider_transport_error" is returned
      And error metadata includes operation "poll" and provider identifier

    Scenario: Unexpected callback payload maps to invalid response
      Given IBM Runtime adapter returns an unexpected payload for submit
      When response normalization is applied
      Then error "provider_invalid_response" is returned
      And diagnostics include operation "submit"
