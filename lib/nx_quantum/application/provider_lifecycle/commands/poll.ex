defmodule NxQuantum.Application.ProviderLifecycle.Commands.Poll do
  @moduledoc false

  @behaviour NxQuantum.Application.ProviderLifecycle.Command

  @impl true
  def operation, do: :poll

  @impl true
  def adapter_fun, do: :poll

  @impl true
  def context([job, opts], _context_opts) do
    metadata = Map.get(job, :metadata, %{})

    {
      Map.get(job, :target, Keyword.get(opts, :target, "unknown_target")),
      Map.get(metadata, :workflow, :unknown_workflow),
      Keyword.get(opts, :observability, [])
    }
  end
end
