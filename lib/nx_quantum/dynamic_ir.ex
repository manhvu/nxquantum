alias NxQuantum.DynamicIR.Executor.SubsetV04
alias NxQuantum.DynamicIR.Validator

defmodule NxQuantum.DynamicIR do
  @moduledoc """
  Dynamic-circuit IR foundation for validation and explicit v0.3 execution boundary.
  """

  @type ir_node :: %{required(:type) => atom(), optional(atom()) => term()}
  @type t :: %{nodes: [ir_node()], registers: MapSet.t(String.t())}

  @spec validate(t()) :: {:ok, t()} | {:error, map()}
  def validate(ir), do: Validator.validate(ir)

  @spec execute(t(), keyword()) :: {:ok, map()} | {:error, map()}
  def execute(ir, opts \\ []) do
    case Keyword.get(opts, :mode, :v0_3_boundary) do
      :v0_3_boundary ->
        {:error,
         %{
           code: :dynamic_execution_not_supported,
           message: "dynamic execution is planned for a future release"
         }}

      :supported_v0_4_subset ->
        SubsetV04.execute(ir, opts)

      mode ->
        {:error, %{code: :unsupported_dynamic_execution_mode, mode: mode}}
    end
  end
end
