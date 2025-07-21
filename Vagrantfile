# Vagrantfile
VAGRANTFILE_API_VERSION = "2"
nodes = [
  { :hostname => "k8s-master",  :ip => "192.168.56.10" },
  { :hostname => "k8s-worker1", :ip => "192.168.56.11" }
]

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "generic/ubuntu2004"
  nodes.each do |node|
    config.vm.define node[:hostname] do |node_config|
      node_config.vm.hostname = node[:hostname]
      node_config.vm.boot_timeout = 600
      node_config.vm.network :private_network, ip: node[:ip]
      node_config.vm.provider "virtualbox" do |vb|
        vb.memory = "2048"
        vb.cpus = 2
      end
      node_config.vm.provision "shell", path: "bootstrap.sh"
    end
  end
end
