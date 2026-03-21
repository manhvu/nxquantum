defmodule NxQuantum.Observability.Profile do
  @moduledoc false

  @allowed [:high_level, :granular, :forensics]

  @spec normalize(term()) :: :high_level | :granular | :forensics
  def normalize(profile) when profile in @allowed, do: profile
  def normalize(profile) when is_binary(profile), do: profile |> String.to_atom() |> normalize()
  def normalize(_), do: :high_level

  @spec enabled?(keyword()) :: boolean()
  def enabled?(opts), do: Keyword.get(opts, :enabled, false)
end
