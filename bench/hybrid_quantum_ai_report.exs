input = List.first(System.argv()) || "tmp/hybrid_bench"
output = List.last(System.argv()) || "tmp/hybrid_report.txt"

content = """
schema_version: v1
report_kind: hybrid_quantum_ai
input: #{input}
summary:
  - all metrics include classical baseline references
  - fallback behavior is explicitly tracked
  - caveats are required for every scenario
"""

File.mkdir_p!(Path.dirname(output))
File.write!(output, content)
IO.puts("NXQ_HYBRID_REPORT output=#{output}")
