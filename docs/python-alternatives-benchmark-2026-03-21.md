# Python Alternatives vs NxQuantum Benchmark (2026-03-21)

## Goal

Run a real local benchmark on equivalent simulator workloads across:

1. NxQuantum
2. Qiskit
3. PennyLane
4. Cirq

## Workload

Single-circuit expectation benchmark repeated in-process:

1. 2-qubit circuit
2. `H(0)`
3. `CNOT(0, 1)`
4. `RY(0.3)` on qubit 1
5. Expectation of `Z` on qubit 1

Benchmark settings:

1. iterations: `2000`
2. warmup: `100`
3. metric: `per_op_ms` (lower is better)

## Environment

- Host: local macOS arm64 dev machine
- Python: `3.9.6`
- NxQuantum runtime profile: `:cpu_portable`
- Python packages:
  - `qiskit==1.4.5`
  - `pennylane==0.38.0`
  - `cirq-core==1.3.0`

## Commands Used

```bash
python3 -m venv .venv-bench
source .venv-bench/bin/activate
python -m pip install --upgrade pip
python -m pip install 'qiskit>=1.2,<2' 'pennylane>=0.38,<0.40' 'cirq-core>=1.3,<1.5'
python -m pip install 'autoray<0.7'
python bench/python_alternatives_benchmark.py --iterations 2000 --warmup 100
```

## Raw Results (3 runs)

| Run | NxQuantum (ms/op) | Qiskit (ms/op) | PennyLane (ms/op) | Cirq (ms/op) |
| --- | ---: | ---: | ---: | ---: |
| 1 | 0.072071 | 0.103979 | 0.412436 | 0.340090 |
| 2 | 0.073941 | 0.103735 | 0.401781 | 0.339375 |
| 3 | 0.073600 | 0.103969 | 0.405483 | 0.339976 |

Median `per_op_ms`:

1. NxQuantum: `0.073600`
2. Qiskit: `0.103969`
3. PennyLane: `0.405483`
4. Cirq: `0.339976`

Relative to NxQuantum median:

1. Qiskit: `1.41x` slower
2. PennyLane: `5.51x` slower
3. Cirq: `4.62x` slower

## Notes and Caveats

1. This benchmark measures repeated local simulation calls on a small circuit, not remote provider execution.
2. Results are useful for relative local-call overhead on this machine, not universal absolute performance claims.
3. A urllib warning appears due system LibreSSL and does not change measured loop timing.

## Benchmark Harness Files

1. `bench/python_alternatives_benchmark.py`
2. `bench/nxquantum_python_comparison.exs`
