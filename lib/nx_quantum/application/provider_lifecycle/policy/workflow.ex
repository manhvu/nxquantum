defmodule NxQuantum.Application.ProviderLifecycle.Policy.Workflow do
  @moduledoc false

  alias NxQuantum.ProviderBridge.Errors

  @allowed [:estimator, :sampler]

  @spec run(map(), atom() | String.t() | module(), String.t() | nil) :: :ok | {:error, map()}
  def run(%{} = request, provider, target) do
    case Map.fetch(request, :workflow) do
      :error -> :ok
      {:ok, nil} -> :ok
      {:ok, workflow} -> validate_workflow(workflow, provider, target)
    end
  end

  defp validate_workflow(workflow, provider, target) do
    if workflow in @allowed do
      :ok
    else
      {:error,
       Errors.capability_mismatch(:submit, provider, :supports_workflow_class,
         metadata: %{provider: provider, target: target, workflow: workflow, reason: :unsupported_workflow_class}
       )}
    end
  end
end
