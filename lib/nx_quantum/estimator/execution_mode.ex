defmodule NxQuantum.Estimator.ExecutionMode do
  @moduledoc false

  @type t :: :deterministic | :stochastic

  @spec classify(keyword()) :: t()
  def classify(opts) do
    if stochastic?(opts), do: :stochastic, else: :deterministic
  end

  @spec deterministic?(keyword()) :: boolean()
  def deterministic?(opts), do: classify(opts) == :deterministic

  @spec stochastic?(keyword()) :: boolean()
  def stochastic?(opts) do
    sampling_enabled?(opts) or non_zero_noise?(opts)
  end

  defp sampling_enabled?(opts) do
    case Keyword.get(opts, :shots) do
      shots when is_integer(shots) and shots > 0 -> true
      _ -> false
    end
  end

  defp non_zero_noise?(opts) do
    noise = Keyword.get(opts, :noise, [])
    depolarizing = Keyword.get(noise, :depolarizing, 0.0)
    amplitude_damping = Keyword.get(noise, :amplitude_damping, 0.0)
    depolarizing != 0.0 or amplitude_damping != 0.0
  end
end
