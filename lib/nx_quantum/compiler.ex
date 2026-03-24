defmodule NxQuantum.Compiler do
  @moduledoc """
  Circuit optimization pipeline facade.

  Provides deterministic optimization and compile diagnostics contracts.
  """

  alias NxQuantum.Circuit
  alias NxQuantum.Compiler.PassPipeline
  alias NxQuantum.Compiler.Target
  alias NxQuantum.Transpiler

  @type pass :: :simplify | :fuse | :cancel | :resynthesize_1q
  @type optimization_level :: 0 | 1 | 2
  @type routing_strategy :: :shortest_path | :sabre_like
  @type scheduling_strategy :: :none | :asap | :alap
  @type calibration_profile :: :none | :balanced | :fidelity_first | :latency_first

  @spec optimize(Circuit.t(), keyword()) :: {Circuit.t(), map()}
  def optimize(%Circuit{} = circuit, opts \\ []) do
    passes = Keyword.get(opts, :passes, [:simplify, :fuse, :cancel, :resynthesize_1q, :simplify])
    before = length(circuit.operations)

    optimized_ops =
      Enum.reduce(passes, circuit.operations, fn pass, operations ->
        PassPipeline.run(pass, operations, opts)
      end)

    optimized = %{circuit | operations: optimized_ops}

    report = %{
      passes: passes,
      gate_count_before: before,
      gate_count_after: length(optimized_ops)
    }

    {optimized, report}
  end

  @spec compile(Circuit.t(), keyword()) :: {:ok, %{circuit: Circuit.t(), report: map()}} | {:error, map()}
  def compile(%Circuit{} = circuit, opts \\ []) do
    with {:ok, target} <- parse_target(opts),
         {:ok, optimization_level} <- parse_optimization_level(opts),
         {:ok, transpiled, transpile_report} <- maybe_transpile(circuit, target, opts) do
      passes = passes_for_level(optimization_level)
      {compiled, optimize_report} = optimize(transpiled, passes: passes)
      routing_strategy = Keyword.get(opts, :routing_strategy, :shortest_path)
      scheduling_strategy = Keyword.get(opts, :scheduling_strategy, :none)
      calibration_profile = Keyword.get(opts, :calibration_profile, :none)

      report = %{
        optimization_level: optimization_level,
        routing: %{
          strategy: routing_strategy,
          summary: Map.take(transpile_report, [:routed_edges, :inserted_swaps, :added_swap_gates]),
          topology_pressure: topology_pressure(transpile_report)
        },
        scheduling: scheduling_report(scheduling_strategy, compiled),
        cost_model: %{
          profile: calibration_profile,
          weights: cost_weights(calibration_profile)
        },
        diagnostics: diagnostics(routing_strategy, scheduling_strategy, calibration_profile),
        optimizer: optimize_report,
        rejected_alternatives: rejected_alternatives(routing_strategy, scheduling_strategy, calibration_profile)
      }

      {:ok, %{circuit: compiled, report: report}}
    end
  end

  defp parse_target(opts) do
    case Keyword.get(opts, :target) do
      nil ->
        {:ok, %Target{gateset: [:h, :x, :y, :z, :rx, :ry, :rz, :cnot], coupling_map: []}}

      %Target{} = target ->
        {:ok, target}

      attrs ->
        Target.new(attrs)
    end
  end

  defp parse_optimization_level(opts) do
    case Keyword.get(opts, :optimization_level, 1) do
      level when level in [0, 1, 2] ->
        {:ok, level}

      level ->
        {:error, %{code: :compiler_invalid_target, stage: :validation, reason: {:invalid_optimization_level, level}}}
    end
  end

  defp maybe_transpile(circuit, %Target{coupling_map: []}, _opts), do: {:ok, circuit, %{}}

  defp maybe_transpile(circuit, %Target{coupling_map: coupling_map}, opts) do
    mode = if Keyword.get(opts, :routing_strategy, :shortest_path) == :sabre_like, do: :insert_swaps, else: :strict

    case Transpiler.run(circuit, topology: {:coupling_map, coupling_map}, mode: mode) do
      {:ok, transpiled, report} -> {:ok, transpiled, report}
      {:error, reason} -> {:error, %{code: :compiler_topology_violation, stage: :routing, reason: reason}}
    end
  end

  defp passes_for_level(0), do: [:simplify]
  defp passes_for_level(1), do: [:simplify, :fuse, :cancel]
  defp passes_for_level(2), do: [:simplify, :fuse, :cancel, :resynthesize_1q, :simplify]

  defp topology_pressure(%{violations: violations}) when is_list(violations), do: %{violations: length(violations)}
  defp topology_pressure(_), do: %{violations: 0}

  defp scheduling_report(:none, _circuit), do: %{strategy: :none, critical_path: 0, idle_windows: 0}

  defp scheduling_report(strategy, %Circuit{operations: ops}),
    do: %{strategy: strategy, critical_path: length(ops), idle_windows: 0}

  defp cost_weights(:none), do: %{depth: 1.0, duration: 1.0, error: 1.0}
  defp cost_weights(:balanced), do: %{depth: 1.0, duration: 1.0, error: 1.0}
  defp cost_weights(:fidelity_first), do: %{depth: 0.8, duration: 0.7, error: 1.5}
  defp cost_weights(:latency_first), do: %{depth: 1.2, duration: 1.5, error: 0.7}

  defp diagnostics(routing_strategy, scheduling_strategy, calibration_profile) do
    [
      %{type: :selected_routing_strategy, value: routing_strategy},
      %{type: :selected_scheduling_strategy, value: scheduling_strategy},
      %{type: :selected_calibration_profile, value: calibration_profile}
    ]
  end

  defp rejected_alternatives(routing_strategy, scheduling_strategy, calibration_profile) do
    %{
      routing: Enum.reject([:shortest_path, :sabre_like], &(&1 == routing_strategy)),
      scheduling: Enum.reject([:none, :asap, :alap], &(&1 == scheduling_strategy)),
      calibration_profile: Enum.reject([:none, :balanced, :fidelity_first, :latency_first], &(&1 == calibration_profile))
    }
  end
end
