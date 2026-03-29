defmodule NxQuantum.AI.Tools.KernelRerank.QuantizedCache do
  @moduledoc false

  @spec get(atom() | :ets.tid(), binary()) :: {:hit, map()} | :miss
  def get(table, key) when is_binary(key) do
    case :ets.lookup(table, key) do
      [{^key, value}] when is_map(value) -> {:hit, value}
      _ -> :miss
    end
  rescue
    _ -> :miss
  end

  @spec put(atom() | :ets.tid(), binary(), map()) :: :ok
  def put(table, key, value) when is_binary(key) and is_map(value) do
    true = :ets.insert(table, {key, value})
    :ok
  rescue
    _ -> :ok
  end
end
