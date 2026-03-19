alias NxQuantum.Kernels

x =
  Nx.tensor([
    [0.0, 0.1],
    [0.2, 0.3],
    [0.4, 0.5],
    [0.6, 0.7]
  ])

k = Kernels.matrix(x, gamma: 0.7, seed: 1234)

IO.inspect(Nx.shape(k), label: "kernel_shape")
IO.inspect(k, label: "kernel_matrix")
