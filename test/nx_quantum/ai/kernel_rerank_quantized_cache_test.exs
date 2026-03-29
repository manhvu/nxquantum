defmodule NxQuantum.AI.KernelRerankQuantizedCacheTest do
  use ExUnit.Case, async: true

  alias NxQuantum.AI.Tools.KernelRerank.QuantizedCache

  test "cache get/put round-trip is deterministic" do
    table = :ets.new(:nxq_quantized_cache_unit, [:set, :public])
    key = "abc123"
    payload = %{codec: :turboquant, schema_version: "v1"}

    assert :miss == QuantizedCache.get(table, key)
    assert :ok == QuantizedCache.put(table, key, payload)
    assert {:hit, ^payload} = QuantizedCache.get(table, key)
  end
end
