# -*- mode: ruby -*-
# vi: set ft=ruby :

IP_ADDRESSES = [
  "10.0.0.2",
  "10.0.0.4",
  "10.0.0.3",
]

BOX = "ubuntu/focal64"

HOSTNAMES = [
  "node0",
  "node1",
  "node2",
]

NODES = 3

Vagrant.configure("2") do |config|
  
  NODES.times do |i|

    config.vm.define "node" + i.to_s() do |node|

      node.vm.box = BOX
      node.vm.hostname = HOSTNAMES[i]

      node.vm.provider :virtualbox do |vm|
        vm.memory = 2048
        vm.cpus = 2
        vm.customize ["modifyvm", :id, "--cpuexecutioncap", "50"]
      end

      node.vm.network "private_network", ip: IP_ADDRESSES[i]

      node.provision "shell", :inline <<EOS
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-focal main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl docker-ce
sudo apt-mark hold kubelet kubeadm kubectl
EOS
    end
  end
end