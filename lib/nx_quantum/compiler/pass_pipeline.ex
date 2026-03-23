defmodule NxQuantum.Compiler.PassPipeline do
  @moduledoc false

  alias NxQuantum.Compiler.Passes.Cancel
  alias NxQuantum.Compiler.Passes.Fuse
  alias NxQuantum.Compiler.Passes.Resynthesize1Q
  alias NxQuantum.Compiler.Passes.Simplify

  @spec run(atom(), list(), keyword()) :: list()
  def run(pass, operations, opts \\ [])
  def run(:simplify, operations, _opts), do: Simplify.run(operations)
  def run(:fuse, operations, _opts), do: Fuse.run(operations)
  def run(:cancel, operations, _opts), do: Cancel.run(operations)
  def run(:resynthesize_1q, operations, opts), do: Resynthesize1Q.run(operations, opts)
  def run(_unknown, operations, _opts), do: operations
end
