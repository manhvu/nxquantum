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

IO.puts("loss_before=#{Nx.to_number(loss_before)}")
IO.puts("loss_after=#{Nx.to_number(loss_after)}")
IO.puts("theta_after=#{Nx.to_number(theta_after)}")
