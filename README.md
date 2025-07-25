# Deploying a Kubernetes Cluster on Bare Metal

This project provisions a **multi-node Kubernetes cluster** on local VMs using **Vagrant + kubeadm** with networking configured via **Calico (VXLAN mode)**.

## Tech Stack

- Vagrant + VirtualBox
- Ubuntu 22.04
- kubeadm
- Calico CNI (VXLAN)
- Containerd

## Project Implementation

- 1 Control plane node
- 1 Worker node
- Calico CNI with VXLAN backend
- Network Troubleshooting
- Correct DNS and pod-to-pod networking across nodes
- Basic connectivity tests

![architecture](docs/assets/architecture-overview.png)

## Docs

- See [setup.md](docs/setup.md) for more details on architecture
- See [troubleshooting.md](docs/troubleshooting.md) for issues encountered along the way
- See [networking-flow.md](docs/networking-flow.md) for more details on networking
