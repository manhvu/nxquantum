defmodule NxQuantum.ProviderBridge.CapabilityContract do
  @moduledoc """
  Canonical provider capability contract.
  """

  @enforce_keys [
    :supports_estimator,
    :supports_sampler,
    :supports_batch,
    :supports_dynamic,
    :supports_cancel_in_running,
    :supports_calibration_payload,
    :target_class
  ]
  defstruct [
    :supports_estimator,
    :supports_sampler,
    :supports_batch,
    :supports_dynamic,
    :supports_cancel_in_running,
    :supports_calibration_payload,
    :target_class
  ]

  @type t :: %__MODULE__{
          supports_estimator: boolean(),
          supports_sampler: boolean(),
          supports_batch: boolean(),
          supports_dynamic: boolean(),
          supports_cancel_in_running: boolean(),
          supports_calibration_payload: boolean(),
          target_class: :gate_model | :analog | :simulator
        }
end
