#!/bin/bash
set -e

# Run common setup
source ./common-bootstrap.sh

# Init Kubernetes with a fixed pod CIDR
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=192.168.56.10

# kubeconfig for vagrant user
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

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

# Deploy Calico - Network Plugin for Kubernetes
# Handles pod networking and gives each pod a unique IP
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.2/manifests/calico.yaml

# Patch the Calico default IPPool to enable VXLAN instead of IPIP
# VXLAN is a tunneling method, sends traffic through hidden tunnels
# VXLAN applies encapsulation method, wraps the internal Pod IPs in a packet and wraps again with an outer layer containing the node IPs
# The receiving node unwraps the VXLAN packet and delivers it
# VXLan does not require special kernel features


# IPPool is the CRD that defines the IP pool that Calico will be used to assign IPs to pods
# CIDR is /16 which gives arround 65K IP addresses
# VXLAN tunnels will be used
cat <<EOF | kubectl apply -f -
apiVersion: crd.projectcalico.org/v1
kind: IPPool
metadata:
  name: default-ipv4-ippool
spec:
  cidr: 10.244.0.0/16
  ipipMode: Never
  vxlanMode: Always
  natOutgoing: true
  disabled: false
EOF

# calico-node DaemonSet to use VXLAN
kubectl -n kube-system patch daemonset calico-node --type merge -p '
spec:
  template:
    spec:
      containers:
      - name: calico-node
        env:
        - name: CALICO_IPV4POOL_IPIP
          value: "Never"
        - name: CALICO_IPV4POOL_VXLAN
          value: "Always"
        readinessProbe: null
        livenessProbe: null
'


# calico-kube-controllers deployment
kubectl -n kube-system patch deployment calico-kube-controllers --type merge -p '
spec:
  template:
    spec:
      containers:
      - name: calico-kube-controllers
        env:
        - name: CALICO_IPV4POOL_IPIP
          value: "Never"
        - name: CALICO_IPV4POOL_VXLAN
          value: "Always"
        readinessProbe: null
        livenessProbe: null
'


kubectl rollout restart daemonset calico-node -n kube-system
kubectl rollout restart deployment calico-kube-controllers -n kube-system

