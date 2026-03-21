Feature: Provider simulation strategy fallback policy

  Rule: Resource-threshold fallback is deterministic
    Scenario: State-vector memory projection above threshold selects MPS fallback
      Given projected state-vector memory exceeds configured execution threshold
      When execution policy evaluates available simulation strategies
      Then deterministic MPS fallback is selected
      And strategy metadata reports threshold and projected memory values
      And fallback reason code is "resource_threshold_exceeded"

  Rule: Provider path unavailability triggers deterministic local fallback
    Scenario: Unavailable or unsupported provider path selects local strategy
      Given provider path is unavailable or requested capability is unsupported
      When execution policy evaluates provider and local strategy options
      Then deterministic local fallback strategy is selected and reported
      And fallback reason code is "provider_path_unavailable_or_unsupported"
      And no implicit provider reroute is performed

  Rule: Fallback accuracy contracts are explicit
    Scenario: Low-entanglement workloads preserve expectation tolerance under MPS
      Given a low-entanglement circuit is executed with MPS fallback
      When expectation values are computed
      Then expectation results remain within tolerance contract
      And tolerance configuration and observed delta are reported deterministically

  Rule: Fallback selection is reproducible
    Scenario: Equivalent policy inputs choose the same strategy and metadata
      Given identical execution policy inputs and identical capability context
      When fallback strategy selection is evaluated multiple times
      Then selected strategy and reported metadata are identical across runs
