defmodule NxQuantum.DynamicIR.Executor.SubsetV04 do
  @moduledoc false

  alias NxQuantum.Application.DynamicIR.Interpreter
  alias NxQuantum.DynamicIR.Validator

  @spec execute(Validator.t(), keyword()) :: {:ok, map()} | {:error, map()}
  def execute(ir, opts \\ []) do
    with {:ok, validated} <- Validator.validate(ir) do
      Interpreter.execute(validated, opts)
    end
  end
end
