Feature: Provider dynamic circuit capabilities

  Rule: Dynamic capability negotiation is deterministic
    Scenario: Supported dynamic path remains typed and deterministic
      Given selected provider supports mid-circuit measurement and feed-forward control
      When a dynamic workflow is submitted
      Then execution path remains typed and deterministic
      And branch decision metadata is preserved
      And register trace metadata is preserved

    Scenario: Unsupported dynamic path fails before remote execution
      Given selected provider does not support dynamic circuit node "mid_circuit_feed_forward"
      When a dynamic workflow is submitted
      Then error "provider_capability_mismatch" is returned before remote execution
      And no remote submit lifecycle call is attempted
