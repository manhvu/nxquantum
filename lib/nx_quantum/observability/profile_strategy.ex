defmodule NxQuantum.Observability.ProfileStrategy do
  @moduledoc false

  @callback emit_metrics(module(), atom(), map(), :ok | :error, keyword()) :: :ok
end
