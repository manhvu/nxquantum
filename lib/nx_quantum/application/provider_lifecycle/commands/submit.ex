defmodule NxQuantum.Application.ProviderLifecycle.Commands.Submit do
  @moduledoc false

  @behaviour NxQuantum.Application.ProviderLifecycle.Command

  @impl true
  def operation, do: :submit

  @impl true
  def adapter_fun, do: :submit

  @impl true
  def context([payload, opts], _context_opts) do
    {
      Keyword.get(opts, :target, "unknown_target"),
      Map.get(payload, :workflow, :unknown_workflow),
      Keyword.get(opts, :observability, [])
    }
  end
end
