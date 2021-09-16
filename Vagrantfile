# -*- mode: ruby -*-
# vi: set ft=ruby :

IP_ADDRESSES = [
  "10.0.0.2",
  "10.0.0.4",
  "10.0.0.3",
]

BOX = "generic/ubuntu1804"

HOSTNAMES = [
  "node0",
  "node1",
  "node2",
]

NODES = 3

Vagrant.configure("2") do |config|
  
  NODES.times do |i|

    config.vm.boot_timeout = 3600

    config.vm.define "node" + i.to_s() do |node|

      node.vm.box = BOX
      node.vm.hostname = HOSTNAMES[i]

      node.vm.provider :libvirtd do |vm|
        vm.memory = 2048
        vm.cpus = 2
      end

      node.vm.synced_folder "./yamls", "/home/vagrant/yamls"

      node.vm.network "private_network", ip: IP_ADDRESSES[i]

      node.vm.provision "shell", inline: <<EOS
set -x
# need to disable swap for kubeadm to work
swapoff -a
sed -i "s@$(grep -E ^UUID=.+swap  /etc/fstab)@@" /etc/fstab
apt update && \
  apt install -y apt-transport-https ca-certificates curl && \
  curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg && \
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
  echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list && \
  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list && \
  apt update && \
  apt install -y kubelet kubeadm kubectl docker-ce && \
  apt-mark hold kubelet kubeadm kubectl && {
    test -d /etc/docker || mkdir /etc/docker
    cat >/etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
    echo "KUBELET_EXTRA_ARGS=--node-ip #{IP_ADDRESSES[i]}" > /etc/default/kubelet
    systemctl restart docker
    usermod -aG docker vagrant
  }
EOS
    end
  end
end
