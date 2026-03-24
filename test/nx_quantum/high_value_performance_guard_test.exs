defmodule NxQuantum.HighValuePerformanceGuardTest do
  use ExUnit.Case, async: true

  @perf_dir Path.expand("../../bench/datasets/perf", __DIR__)
  @matrix_script Path.expand("../../bench/high_value_performance_matrix.exs", __DIR__)

  test "high-value matrix script and required manifests exist" do
    assert File.exists?(@matrix_script)

    Enum.each(
      [
        "state_reuse_8q_xy_v1.manifest.json",
        "batch_obs_8q_v1.manifest.json",
        "sampled_counts_sparse_terms_v1.manifest.json",
        "shot_sweep_param_grid_v1.manifest.json"
      ],
      fn file ->
        path = Path.join(@perf_dir, file)
        assert File.exists?(path)
        content = File.read!(path)
        assert content =~ "\"dataset_id\""
        assert content =~ ~s("schema_version": "v1")
        assert content =~ "\"seed\""
        assert content =~ "\"sha256\""
      end
    )
  end

  test "shot sweep dataset uses fixed shot tiers and pinned grid metadata" do
    manifest = @perf_dir |> Path.join("shot_sweep_param_grid_v1.manifest.json") |> File.read!()

    assert manifest =~ ~s("grid_id": "shot_sweep_param_grid_v1")
    assert manifest =~ "\"parameter_count\": 2"
    assert manifest =~ "\"sweep_seed\": 20260323"
    assert manifest =~ "\"shot_tiers\": [256, 1024, 4096]"

    rows =
      @perf_dir
      |> Path.join("shot_sweep_param_grid_v1.jsonl")
      |> File.stream!()
      |> Enum.map(&String.trim/1)

    assert Enum.any?(rows, &String.contains?(&1, "\"shots\":256"))
    assert Enum.any?(rows, &String.contains?(&1, "\"shots\":1024"))
    assert Enum.any?(rows, &String.contains?(&1, "\"shots\":4096"))
  end
end
