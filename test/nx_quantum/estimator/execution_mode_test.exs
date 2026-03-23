defmodule NxQuantum.Estimator.ExecutionModeTest do
  use ExUnit.Case, async: true

  alias NxQuantum.Estimator.ExecutionMode

  describe "classify/1" do
    test "returns deterministic when shots and noise are absent" do
      assert :deterministic = ExecutionMode.classify([])
      assert ExecutionMode.deterministic?([])
      refute ExecutionMode.stochastic?([])
    end

    test "returns stochastic when valid shots are configured" do
      assert :stochastic = ExecutionMode.classify(shots: 128)
      refute ExecutionMode.deterministic?(shots: 128)
      assert ExecutionMode.stochastic?(shots: 128)
    end

    test "returns stochastic when depolarizing noise is configured" do
      assert :stochastic = ExecutionMode.classify(noise: [depolarizing: 0.1])
    end

    test "returns stochastic when amplitude damping noise is configured" do
      assert :stochastic = ExecutionMode.classify(noise: [amplitude_damping: 0.2])
    end
  end
end
