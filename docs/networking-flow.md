# Networking Flow

## Pod to Pod communication across nodes

- A pod named dns-test on Node 1 wants to contact a pod named my-app on Node 2

```bash
1. dns-test runs: nslookup my-app
   ↓
2. This sends a DNS request to CoreDNS (10.96.0.10)
   ↓
3. CoreDNS looks up "my-app" and returns its ClusterIP (e.g. 10.96.0.150)
   ↓
4. dns-test sends a request to 10.96.0.150 (ClusterIP of the service)
   ↓
5. kube-proxy on Node1 intercepts the traffic to 10.96.0.150
   ↓
6. kube-proxy picks one of the endpoints (actual pod IPs behind my-app service)
   ↓
7. The request is NATed (rewritten) and forwarded to the selected Pod (e.g. my-app Pod on Node2, say 10.244.200.20) and routed over the overlay network (e.g Calico VXLan) to Node 2
   ↓
8. my-app Pod receives the request and replies.

```

- CoreDNS is Kubernetes' internal resolution service. It maps hostnames to IPs as shown in step 3
- Kube proxy is a daemonset that runs on every node and can see any Kubernetes service bound to any pod on any node and automatically know the real Pod IP address behind the static service

## DNS resolution flow

The below flow happens by executing into a pod and running nslookup kubernetes.default

```bash
[dns-test Pod]
      |
      | nslookup kubernetes.default
      v
[CoreDNS Service]
      |
      | (resolves to service IP)
      v
[kubernetes.default Service - 10.96.0.1]
      |
      v
[Kubernetes API Server]
```

- The CIDR allocation range defined by kubeadm init command is 10.96.0.0/12 and the first IP address in that range (10.96.0.1) is assigned to the Kubernetes API server service
