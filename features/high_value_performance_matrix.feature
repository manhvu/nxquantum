Feature: High-value performance matrix

  Rule: Performance claims are anchored to reproducible Q/ML workloads

    Scenario Outline: High-value simulation scenario <scenario_id> has pinned evidence contracts
      Given performance scenario <scenario_id> is prioritized for Q/ML engineering decisions
      When benchmark harness coverage for <scenario_id> is delivered
      Then deterministic harness includes scenario <scenario_id> with version-pinned runtime metadata
      And performance dataset manifests include dataset_id schema_version seed and sha256 fields
      And CI regression guards enforce scenario-specific thresholds for <scenario_id>
      And all roadmap expectations for this feature are implementation-ready

      Examples:
        | scenario_id                 |
        | baseline_2q                 |
        | deep_6q                     |
        | state_reuse_8q_xy           |
        | batch_obs_8q                |
        | sampled_counts_sparse_terms |
        | shot_sweep_param_grid_v1    |

    Scenario: Shot-heavy parameter sweep datasets are fixed and auditable
      Given shot-heavy parameter sweep benchmarking is required for provider-relevant workloads
      When shot sweep dataset contracts are finalized
      Then shot sweep datasets include fixed shot tiers 256 1024 and 4096 with pinned parameter grid metadata
      And shot sweep manifests include grid_id parameter_count and sweep_seed fields
      And report outputs include latency throughput and fallback-rate measurements for each shot tier
      And all roadmap expectations for this feature are implementation-ready

    Scenario Outline: Provider lifecycle latency lane <lane> is benchmarked end-to-end
      Given provider lifecycle latency benchmarking supports <lane> lane execution
      When provider lifecycle benchmark scripts for <lane> are implemented
      Then provider lifecycle latency scripts cover submit poll cancel and fetch_result for <lane> lanes
      And lane reports include transport mode provider target and credential policy metadata
      And benchmark reports publish version-pinned Qiskit and Cirq comparisons with explicit caveat labels
      And all roadmap expectations for this feature are implementation-ready

      Examples:
        | lane       |
        | fixture    |
        | live_smoke |
        | live       |
