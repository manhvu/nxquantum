# Model Recipes

Deterministic workflow recipes for v0.2 advanced ML usage.

## 1) Quantum Kernel + Classical Model

Use `NxQuantum.Kernels.matrix/2` to produce a deterministic Gram matrix:

```elixir
x = Nx.tensor([[0.1, 0.2], [0.3, 0.4], [0.5, 0.6]])
k = NxQuantum.Kernels.matrix(x, gamma: 0.7, seed: 1234)
```

Then feed `k` into your classical kernel pipeline (ridge/SVM-like workflows).

See:

- `examples/quantum_kernel_classifier.exs`

## 2) Hybrid Scalar Head Training

Optimize a variational parameter with `Estimator.expectation/2` + `Grad.value_and_grad/3`.

See:

- `docs/axon-integration.md`
- `examples/axon_hybrid_train_step.exs`

## 3) Noisy/Shot-Based Evaluation

For deterministic experiments with realistic execution assumptions:

```elixir
NxQuantum.Estimator.expectation_result(
  circuit,
  shots: 2048,
  seed: 2026,
  noise: [depolarizing: 0.1, amplitude_damping: 0.2]
)
```

Keep seed and noise config fixed between runs for reproducibility.
