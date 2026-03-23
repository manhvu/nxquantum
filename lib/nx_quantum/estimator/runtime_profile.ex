defmodule NxQuantum.Estimator.RuntimeProfile do
  @moduledoc false

  alias NxQuantum.Runtime

  @spec resolve(keyword()) :: {:ok, Runtime.profile()} | {:error, map()}
  def resolve(opts) do
    runtime_profile = Keyword.get(opts, :runtime_profile, :cpu_portable)
    fallback_policy = Keyword.get(opts, :fallback_policy, :strict)
    runtime_available? = Keyword.get(opts, :runtime_available?, true)

    resolve(runtime_profile, fallback_policy, runtime_available?)
  end

  defp resolve(:cpu_portable, _fallback_policy, true) do
    {:ok, Runtime.profile!(:cpu_portable)}
  end

  defp resolve(runtime_profile, fallback_policy, runtime_available?) do
    Runtime.resolve(
      runtime_profile,
      fallback_policy: fallback_policy,
      runtime_available?: runtime_available?
    )
  end
end
