defmodule NxQuantum.Observability.Profile do
  @moduledoc false

  @allowed [:high_level, :granular, :forensics]

  @spec normalize(term()) :: :high_level | :granular | :forensics
  def normalize(profile) when profile in @allowed, do: profile

  def normalize(profile) when is_binary(profile) do
    case String.downcase(profile) do
      "high_level" -> :high_level
      "granular" -> :granular
      "forensics" -> :forensics
      _ -> :high_level
    end
  end

  def normalize(_), do: :high_level

  @spec enabled?(keyword()) :: boolean()
  def enabled?(opts), do: Keyword.get(opts, :enabled, false)
end
