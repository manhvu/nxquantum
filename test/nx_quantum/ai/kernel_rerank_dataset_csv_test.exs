defmodule NxQuantum.AI.KernelRerankDatasetCSVTest do
  use ExUnit.Case, async: true

  alias NxQuantum.AI.Tools.KernelRerank.DatasetCSV

  test "load/1 parses deterministic dataset rows for a query" do
    path = write_dataset!("dataset_csv_ok.csv", dataset_fixture())

    assert {:ok, loaded} =
             DatasetCSV.load(%{
               dataset_path: path,
               query_id: "q-1",
               candidate_ids: ["d-2", "d-1"]
             })

    assert loaded.candidate_ids == ["d-2", "d-1"]
    assert loaded.dataset_query_id == "q-1"
    assert loaded.dataset_source == "dataset_csv_ok.csv"
    assert loaded.query_embedding == [0.7, 0.2, -0.1, 0.9]
    assert loaded.candidate_embeddings["d-1"] == [0.8, 0.1, -0.2, 0.8]
  end

  test "load/1 returns typed error when file is missing" do
    assert {:error, error} =
             DatasetCSV.load(%{
               dataset_path: Path.join(System.tmp_dir!(), "does_not_exist.csv"),
               query_id: "q-1"
             })

    assert error.code == :ai_tool_invalid_request
    assert error.field == :dataset_path
  end

  defp write_dataset!(filename, body) do
    path = Path.join(System.tmp_dir!(), filename)
    File.write!(path, body)
    path
  end

  defp dataset_fixture do
    """
    query_id,candidate_id,query_embedding,candidate_embedding,label,classical_score
    q-1,d-1,0.7|0.2|-0.1|0.9,0.8|0.1|-0.2|0.8,3,0.91
    q-1,d-2,0.7|0.2|-0.1|0.9,0.6|0.2|-0.3|0.7,2,0.77
    q-1,d-3,0.7|0.2|-0.1|0.9,0.1|0.8|0.4|-0.1,0,0.21
    q-2,d-4,0.2|0.3|0.1|0.4,0.0|0.2|0.8|0.5,1,0.44
    """
  end
end
