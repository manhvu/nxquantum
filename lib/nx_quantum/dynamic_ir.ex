defmodule NxQuantum.DynamicIR do
  @moduledoc """
  Dynamic-circuit IR foundation for validation and explicit v0.3 execution boundary.
  """

  @type ir_node :: %{required(:type) => atom(), optional(atom()) => term()}
  @type t :: %{nodes: [ir_node()], registers: MapSet.t(String.t())}

  @spec validate(t()) :: {:ok, t()} | {:error, map()}
  def validate(%{nodes: nodes, registers: registers} = ir) when is_list(nodes) do
    with :ok <- validate_registers_type(registers),
         :ok <- validate_nodes(nodes) do
      validate_dependencies(ir)
    end
  end

  def validate(_invalid) do
    {:error, %{code: :invalid_dynamic_ir, reason: :invalid_ir_shape}}
  end

  @spec execute(t(), keyword()) :: {:error, map()}
  def execute(_ir, _opts \\ []) do
    {:error,
     %{
       code: :dynamic_execution_not_supported,
       message: "dynamic execution is planned for a future release"
     }}
  end

  defp validate_registers_type(registers) do
    if match?(%MapSet{}, registers),
      do: :ok,
      else: {:error, %{code: :invalid_dynamic_ir, reason: :invalid_register_set}}
  end

  defp validate_nodes(nodes) do
    if Enum.all?(nodes, &is_map/1),
      do: :ok,
      else: {:error, %{code: :invalid_dynamic_ir, reason: :invalid_node_shape}}
  end

  defp validate_dependencies(%{nodes: nodes, registers: declared} = ir) do
    validation =
      Enum.reduce_while(nodes, MapSet.new(), fn node, produced ->
        case node do
          %{type: :measure, register: register} when is_binary(register) ->
            {:cont, MapSet.put(produced, register)}

          %{type: :conditional_gate, register: register} when is_binary(register) ->
            if MapSet.member?(produced, register) or MapSet.member?(declared, register) do
              {:cont, produced}
            else
              {:halt, {:error, %{code: :invalid_dynamic_ir, register: register}}}
            end

          %{type: _other} ->
            {:cont, produced}

          _ ->
            {:halt, {:error, %{code: :invalid_dynamic_ir, reason: :invalid_node_shape}}}
        end
      end)

    case validation do
      {:error, _} = error -> error
      _produced -> {:ok, ir}
    end
  end
end
