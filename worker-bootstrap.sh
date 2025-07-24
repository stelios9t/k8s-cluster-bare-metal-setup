#!/bin/bash
set -e

# Run common setup
source ./bootstrap-common.sh

# Set NODE_IP manually to avoid kubelet registering default NAT IP
# NAT IP is 10.0.2.15 and is automatically set by all VMs by Vagrant on interface enp0s3
# Interface enp0s8 contains the actual IP address of the private network we set up for Kubernetes to communicate
NODE_IP=$(ip -4 addr show enp0s8 | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n 1)

echo "Setting node IP to: $NODE_IP"

# Patch kubeadm-flags.env with the real node ip
sudo sed -i '/--node-ip/d' /var/lib/kubelet/kubeadm-flags.env
echo "KUBELET_KUBEADM_ARGS=\"--container-runtime-endpoint=unix:///var/run/containerd/containerd.sock --pod-infra-container-image=registry.k8s.io/pause:3.9 --node-ip=${NODE_IP}\"" | sudo tee /var/lib/kubelet/kubeadm-flags.env

# Restart kubelet to apply changes
sudo systemctl daemon-reexec
sudo systemctl restart kubelet

# Join command will be added manually here after control-plane init
# Example:
# sudo kubeadm join 192.168.56.10:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>
