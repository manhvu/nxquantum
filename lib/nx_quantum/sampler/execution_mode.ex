defmodule NxQuantum.Sampler.ExecutionMode do
  @moduledoc false

  @type batch_mode :: :sequential | :parallel

  @spec classify_batch(keyword()) :: batch_mode()
  def classify_batch(opts) do
    if Keyword.get(opts, :parallel, false), do: :parallel, else: :sequential
  end

  @spec max_concurrency(keyword()) :: pos_integer()
  def max_concurrency(opts) do
    opts
    |> Keyword.get(:max_concurrency, System.schedulers_online())
    |> normalize_concurrency()
  end

  defp normalize_concurrency(value) when is_integer(value) and value > 0, do: value
  defp normalize_concurrency(_), do: System.schedulers_online()
end
