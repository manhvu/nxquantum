defmodule NxQuantum.Estimator.RuntimeProfile do
  @moduledoc false

  alias NxQuantum.Estimator.RuntimeAutoSelector
  alias NxQuantum.Runtime

  @spec resolve(keyword()) :: {:ok, Runtime.profile()} | {:error, map()}
  def resolve(opts) do
    with {:ok, selection} <- resolve_with_context(opts, []) do
      {:ok, selection.profile}
    end
  end

  @spec resolve_with_context(keyword(), keyword()) :: {:ok, map()} | {:error, map()}
  def resolve_with_context(opts, context_opts \\ []) do
    runtime_profile = requested_profile(opts)
    fallback_policy = Keyword.get(opts, :fallback_policy, :strict)

    case runtime_profile do
      :auto ->
        selection = RuntimeAutoSelector.choose(opts, context_opts)

        {:ok,
         %{
           profile: selection.profile,
           requested_profile: :auto,
           selected_profile: selection.profile.id,
           source: :auto,
           reason: selection.reason
         }}

      requested ->
        runtime_available? = Keyword.get(opts, :runtime_available?, true)

        with {:ok, profile} <- resolve_explicit(requested, fallback_policy, runtime_available?) do
          reason = if profile.id == requested, do: :explicit_request, else: :fallback_policy

          {:ok,
           %{
             profile: profile,
             requested_profile: requested,
             selected_profile: profile.id,
             source: :explicit,
             reason: reason
           }}
        end
    end
  end

  @spec apply_selection_metadata(keyword(), map()) :: keyword()
  def apply_selection_metadata(opts, selection) do
    resolved = selection.selected_profile

    opts
    |> Keyword.put(:runtime_profile, resolved)
    |> Keyword.put(:runtime_profile_requested, selection.requested_profile)
    |> Keyword.put(:runtime_profile_resolved, resolved)
    |> Keyword.put(:runtime_profile_selection_source, selection.source)
    |> Keyword.put(:runtime_profile_selection_reason, selection.reason)
  end

  defp resolve_explicit(:cpu_portable, _fallback_policy, true) do
    {:ok, Runtime.profile!(:cpu_portable)}
  end

  defp resolve_explicit(runtime_profile, fallback_policy, runtime_available?) do
    Runtime.resolve(
      runtime_profile,
      fallback_policy: fallback_policy,
      runtime_available?: runtime_available?
    )
  end

  defp requested_profile(opts) do
    case Keyword.get(opts, :runtime_profile, :cpu_portable) do
      %{id: id} when is_atom(id) -> id
      id -> id
    end
  end
end
