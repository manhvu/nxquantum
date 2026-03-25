defmodule NxQuantum.Estimator.ResultBuilder do
  @moduledoc false

  alias NxQuantum.Estimator.Result

  @spec build(Nx.Tensor.t(), [map()], keyword()) :: Result.t()
  def build(values, observable_specs, opts) do
    resolved_runtime_profile = runtime_profile_id(opts)
    requested_runtime_profile = Keyword.get(opts, :runtime_profile_requested, resolved_runtime_profile)

    %Result{
      values: values,
      metadata: %{
        mode: :estimator,
        observables: observable_specs,
        runtime_profile: resolved_runtime_profile,
        runtime_selection: %{
          requested_profile: requested_runtime_profile,
          selected_profile: Keyword.get(opts, :runtime_profile_resolved, resolved_runtime_profile),
          source: Keyword.get(opts, :runtime_profile_selection_source, :explicit),
          reason: Keyword.get(opts, :runtime_profile_selection_reason, :explicit_request)
        },
        shots: Keyword.get(opts, :shots),
        seed: Keyword.get(opts, :seed)
      }
    }
  end

  defp runtime_profile_id(opts) do
    case Keyword.get(opts, :runtime_profile, :cpu_portable) do
      %{id: id} when is_atom(id) -> id
      id when is_atom(id) -> id
      _ -> :cpu_portable
    end
  end
end
