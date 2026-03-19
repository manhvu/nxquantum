defmodule NxQuantum.Runtime.Scale do
  @moduledoc false

  alias NxQuantum.Runtime.Scale.Decision

  @type strategy :: :auto | :dense_only | :large_scale_preferred

  @spec select(strategy(), non_neg_integer(), keyword()) :: {:ok, Decision.t()} | {:error, map()}
  def select(strategy, qubit_count, opts \\ [])

  def select(strategy, qubit_count, opts)
      when strategy in [:auto, :dense_only, :large_scale_preferred] and is_integer(qubit_count) and qubit_count >= 0 do
    dense_threshold = Keyword.get(opts, :dense_threshold, 20)

    cond do
      qubit_count <= dense_threshold ->
        {:ok,
         %Decision{
           selected_path: :dense_state_vector,
           report: report(strategy, qubit_count, dense_threshold, :dense_state_vector)
         }}

      strategy == :dense_only ->
        {:error,
         %{
           code: :scaling_limit_exceeded,
           qubit_count: qubit_count,
           strategy: strategy,
           dense_threshold: dense_threshold
         }}

      true ->
        {:ok,
         %Decision{
           selected_path: :tensor_network_fallback,
           report: report(strategy, qubit_count, dense_threshold, :tensor_network_fallback)
         }}
    end
  end

  def select(strategy, qubit_count, _opts) do
    {:error, %{code: :invalid_scale_strategy, strategy: strategy, qubit_count: qubit_count}}
  end

  defp report(strategy, qubit_count, dense_threshold, selected_path) do
    %{
      selected_strategy: strategy,
      selected_path: selected_path,
      qubit_count: qubit_count,
      dense_threshold: dense_threshold
    }
  end
end
