defmodule NxQuantum.TestSupport.ProviderMatrix do
  @moduledoc false

  alias NxQuantum.Adapters.Providers.AwsBraket
  alias NxQuantum.Adapters.Providers.AzureQuantum
  alias NxQuantum.Adapters.Providers.GoogleQuantumAI
  alias NxQuantum.Adapters.Providers.IBMRuntime

  @type suite_tag ::
          :capability_contracts
          | :cross_platform
          | :observability
          | :live_execution
          | :transport_readiness
          | :batched_primitives

  @type entry :: %{
          id: atom(),
          label: String.t(),
          adapter: module(),
          target: String.t(),
          provider_config: map(),
          suite_tags: [suite_tag()]
        }

  @entries [
    %{
      id: :ibm_runtime,
      label: "IBM Runtime",
      adapter: IBMRuntime,
      target: "ibm_backend_simulator",
      provider_config: %{auth_token: "ibm-token", channel: "ibm_cloud", backend: "ibm_backend_simulator"},
      suite_tags: [
        :capability_contracts,
        :cross_platform,
        :observability,
        :live_execution,
        :transport_readiness,
        :batched_primitives
      ]
    },
    %{
      id: :aws_braket,
      label: "AWS Braket",
      adapter: AwsBraket,
      target: "arn:aws:braket:::device/quantum-simulator/amazon/sv1",
      provider_config: %{
        region: "us-east-1",
        credentials_profile: "default",
        device_arn: "arn:aws:braket:::device/quantum-simulator/amazon/sv1"
      },
      suite_tags: [
        :capability_contracts,
        :cross_platform,
        :observability,
        :live_execution,
        :transport_readiness,
        :batched_primitives
      ]
    },
    %{
      id: :azure_quantum,
      label: "Azure Quantum",
      adapter: AzureQuantum,
      target: "azure.quantum.sim",
      provider_config: %{
        workspace: "ws-1",
        auth_context: "managed_identity",
        target_id: "azure.quantum.sim",
        provider_name: "microsoft"
      },
      suite_tags: [
        :capability_contracts,
        :cross_platform,
        :observability,
        :live_execution,
        :transport_readiness,
        :batched_primitives
      ]
    },
    %{
      id: :google_quantum_ai,
      label: "Google Quantum AI",
      adapter: GoogleQuantumAI,
      target: "projects/example/locations/us-central1/processors/rainbow",
      provider_config: %{
        auth_token: "google-token",
        project_id: "example",
        location: "us-central1",
        processor_id: "projects/example/locations/us-central1/processors/rainbow"
      },
      suite_tags: [
        :capability_contracts,
        :cross_platform,
        :observability,
        :live_execution,
        :transport_readiness,
        :batched_primitives
      ]
    }
  ]

  @spec entries() :: [entry()]
  def entries do
    Enum.sort_by(@entries, & &1.id)
  end

  @spec entries_for(suite_tag()) :: [entry()]
  def entries_for(suite_tag) do
    Enum.filter(entries(), &(suite_tag in &1.suite_tags))
  end

  @spec entry!(atom()) :: entry()
  def entry!(id) when is_atom(id) do
    case Enum.find(entries(), &(&1.id == id)) do
      nil -> raise ArgumentError, "unknown provider id: #{inspect(id)}"
      entry -> entry
    end
  end
end
