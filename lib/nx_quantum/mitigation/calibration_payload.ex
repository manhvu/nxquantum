defmodule NxQuantum.Mitigation.CalibrationPayload do
  @moduledoc false

  @spec validate(map()) :: {:ok, map()} | {:error, map()}
  def validate(payload) do
    with {:ok, normalized} <- normalize_payload(payload),
         :ok <- validate_shape(normalized.matrix) do
      {:ok, normalized}
    end
  end

  @spec metadata(map()) :: map()
  def metadata(%{version: version, source: source}) do
    %{calibration_version: version, calibration_source: source}
  end

  defp normalize_payload(%{matrix: %Nx.Tensor{} = matrix, version: version, source: source})
       when is_binary(version) and is_binary(source) do
    {:ok, %{matrix: matrix, version: version, source: source}}
  end

  defp normalize_payload(%{matrix: %Nx.Tensor{} = matrix}) do
    {:error, invalid_payload_error(expected_shape: {2, 2}, received_shape: Nx.shape(matrix))}
  end

  defp normalize_payload(_invalid) do
    {:error, invalid_payload_error(reason: :missing_matrix_or_metadata, expected_shape: {2, 2})}
  end

  defp validate_shape(matrix) do
    case Nx.shape(matrix) do
      {2, 2} -> :ok
      shape -> {:error, invalid_payload_error(expected_shape: {2, 2}, received_shape: shape)}
    end
  end

  defp invalid_payload_error(attrs) do
    attrs
    |> Map.new()
    |> Map.put(:code, :invalid_calibration_payload)
  end
end
