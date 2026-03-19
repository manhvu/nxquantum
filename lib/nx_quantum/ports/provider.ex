defmodule NxQuantum.Ports.Provider do
  @moduledoc """
  Provider bridge contract for hardware-facing job lifecycle behavior.
  """

  @type provider_id :: atom() | String.t()
  @type job_state :: :submitted | :running | :completed | :cancelled
  @type payload :: map()
  @type job :: %{required(:id) => String.t(), required(:state) => job_state(), optional(atom()) => term()}
  @type result_payload :: %{
          required(:job_id) => String.t(),
          required(:state) => job_state(),
          required(:payload) => payload()
        }

  @callback provider_id() :: provider_id()
  @callback submit(payload(), keyword()) :: {:ok, job()} | {:error, term()}
  @callback poll(job(), keyword()) :: {:ok, job()} | {:error, term()}
  @callback cancel(job(), keyword()) :: {:ok, job()} | {:error, term()}
  @callback fetch_result(job(), keyword()) :: {:ok, result_payload()} | {:error, term()}
end
