defmodule NxQuantum.Application.ProviderLifecycle.Command do
  @moduledoc false

  @callback operation() :: :submit | :poll | :cancel | :fetch_result
  @callback adapter_fun() :: :submit | :poll | :cancel | :fetch_result
  @callback context([term()], keyword()) :: {String.t(), atom(), keyword()}
end
