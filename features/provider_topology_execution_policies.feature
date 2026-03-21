Feature: Provider topology execution policies

  Rule: Topology policy by target class is explicit
    Scenario: Heavy-hex target produces deterministic routing and swap diagnostics
      Given heavy-hex target topology is selected
      When transpilation runs
      Then swap insertion and depth delta are reported deterministically
      And routed edges are included in routing metadata
      And logical-to-physical mapping is included in routing metadata

    Scenario: All-to-all target minimizes swap insertion by policy
      Given all-to-all target topology is selected
      When transpilation runs
      Then swap insertion is minimized or zero by policy
      And routing metadata explicitly reports zero or minimal swap behavior
