# Axon Integration Guide

This guide shows a deterministic hybrid training pattern using `NxQuantum` expectations
inside an Axon-style training loop.

## Goal

Train a scalar parameter `theta` where the quantum head predicts:

- `prediction(theta) = <Z> = cos(theta)`

and the loss is:

- `loss(theta) = (prediction(theta) - target)^2`

## Minimal Deterministic Train Step

```elixir
alias NxQuantum.Circuit
alias NxQuantum.Estimator
alias NxQuantum.Gates
alias NxQuantum.Grad

target = Nx.tensor(1.0)
theta = Nx.tensor(1.57)
lr = 0.1

objective = fn t ->
  circuit =
    Circuit.new(qubits: 1)
    |> Gates.ry(0, theta: t)

  prediction =
    Estimator.expectation(
      circuit,
      observable: :pauli_z,
      wire: 0,
      runtime_profile: :cpu_portable
    )

  Nx.pow(prediction - target, 2)
end

{loss_before, grad} = Grad.value_and_grad(objective, theta, mode: :backprop)
theta_after = theta - lr * grad
loss_after = objective.(theta_after)
```

## Practical Notes

1. Keep runtime profile explicit (`:cpu_portable`, `:cpu_compiled`, etc.).
2. Seed all stochastic paths (`shots`, data order, parameter initialization).
3. Use `Grad.value_and_grad/3` mode selection explicitly for experiments.

## End-to-End Example

See:

- `examples/axon_hybrid_train_step.exs`
