VAGRANTFILE_API_VERSION = "2"

nodes = [
  { name: "controlplane-k8s", ip: "192.168.56.10", script: "controlplane-bootstrap.sh" },
  { name: "k8s-worker1",       ip: "192.168.56.11", script: "worker-bootstrap.sh" }
]

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "ubuntu/jammy64" # Ubuntu 22.04

  nodes.each do |node|
    config.vm.define node[:name] do |node_config|
      node_config.vm.hostname = node[:name]
      node_config.vm.network "private_network", ip: node[:ip]

      node_config.vm.provider "virtualbox" do |vb|
        vb.name = node[:name]
        vb.memory = 4096
        vb.cpus = 3
      end

      node_config.vm.provision "shell", path: "common-bootstrap.sh"
      node_config.vm.provision "shell", path: node[:script]
    end
  end
end

# after both nodes are bootstrapped run this command on master kubeadm token create --print-join-command
# and ssh to worker to join the node in the cluster:
# Example:
# sudo kubeadm join 192.168.56.10:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>
