defmodule NxQuantum.Sampler.ExecutionModeTest do
  use ExUnit.Case, async: true

  alias NxQuantum.Sampler.ExecutionMode

  describe "classify_batch/1" do
    test "returns sequential by default" do
      assert :sequential = ExecutionMode.classify_batch([])
    end

    test "returns parallel when enabled" do
      assert :parallel = ExecutionMode.classify_batch(parallel: true)
    end
  end

  describe "max_concurrency/1" do
    test "uses provided positive value" do
      assert 3 == ExecutionMode.max_concurrency(max_concurrency: 3)
    end

    test "falls back to scheduler count for invalid value" do
      assert System.schedulers_online() == ExecutionMode.max_concurrency(max_concurrency: 0)
    end
  end
end
