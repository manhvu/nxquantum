defmodule NxQuantum.AI.KernelRerankExecutionStrategyTest do
  use ExUnit.Case, async: true

  alias NxQuantum.AI.Tools.KernelRerank.ExecutionStrategy

  test "auto mode selects scalar for small workloads" do
    strategy = ExecutionStrategy.select(8, 64, [])
    assert strategy.mode == :scalar
    assert strategy.max_concurrency == 1
    assert strategy.reason == :below_parallel_threshold
  end

  test "auto mode selects parallel for large workloads" do
    strategy = ExecutionStrategy.select(128, 256, [])
    assert strategy.mode == :parallel
    assert strategy.max_concurrency >= 1
    assert strategy.chunk_size >= 1
    assert strategy.reason == :parallel_threshold_met
    assert strategy.estimated_work >= 1
  end

  test "force modes override auto thresholds" do
    scalar = ExecutionStrategy.select(256, 256, parallel_mode: :force_scalar, max_concurrency: 8)
    parallel = ExecutionStrategy.select(4, 4, parallel_mode: :force_parallel, max_concurrency: 4)

    assert scalar.mode == :scalar
    assert scalar.reason == :forced_scalar
    assert parallel.mode == :parallel
    assert parallel.max_concurrency == 4
    assert parallel.reason == :forced_parallel
  end
end
