defmodule NxQuantum.Runtime.Scale.Decision do
  @moduledoc false

  @enforce_keys [:selected_path, :report]
  defstruct [:selected_path, :report]

  @type t :: %__MODULE__{
          selected_path: :dense_state_vector | :tensor_network_fallback,
          report: map()
        }
end
