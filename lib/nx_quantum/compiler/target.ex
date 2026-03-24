defmodule NxQuantum.Compiler.Target do
  @moduledoc """
  Compiler target contract v1.
  """

  @enforce_keys [:gateset, :coupling_map]
  defstruct [
    :gateset,
    :coupling_map,
    :durations,
    :error_rates,
    :readout,
    :calibration_snapshot_id
  ]

  @type t :: %__MODULE__{
          gateset: [atom()],
          coupling_map: [{non_neg_integer(), non_neg_integer()}],
          durations: map() | nil,
          error_rates: map() | nil,
          readout: map() | nil,
          calibration_snapshot_id: String.t() | nil
        }

  @spec new(map() | keyword()) :: {:ok, t()} | {:error, map()}
  def new(attrs) when is_map(attrs) or is_list(attrs) do
    attrs_map = Map.new(attrs)
    gateset = Map.get(attrs_map, :gateset, [])
    coupling_map = Map.get(attrs_map, :coupling_map, [])

    cond do
      not is_list(gateset) or gateset == [] ->
        {:error, %{code: :compiler_invalid_target, stage: :validation, reason: :invalid_gateset}}

      not is_list(coupling_map) ->
        {:error, %{code: :compiler_invalid_target, stage: :validation, reason: :invalid_coupling_map}}

      true ->
        {:ok, struct(__MODULE__, attrs_map)}
    end
  end
end
