#! /bin/bash

_vagrant() {
    docker run -it --rm --name vagrant \
        -e LIBVIRT_DEFAULT_URI \
        -v /var/run/libvirt/:/var/run/libvirt/ \
        -v ~/.vagrant.d:/.vagrant.d \
        -v $(pwd):$(pwd) \
        -w $(pwd) \
        --network host \
        vagrantlibvirt/vagrant-libvirt:latest vagrant "$@"
}

_ssh() {
    ssh -F ssh.conf $1 sh -xc \'$2\'
}

init_cluster() {
    # only have one control plane atm
    local master=${!master_nodes[@]}
    # _ssh $master 'sudo swapoff -a'
    _ssh $master \
        "sudo kubeadm init --apiserver-advertise-address=${master_nodes[$master]} --pod-network-cidr=192.168.31.0/24"
    _ssh $master 'mkdir -p $HOME/.kube'
    _ssh $master 'sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config'
    _ssh $master 'sudo chown $(id -u):$(id -g) $HOME/.kube/config'
    _ssh $master 'kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 -w0)"'
}

get_hash() {
    _ssh ${!master_nodes[@]} \
        'openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt 
        | openssl rsa -pubin -outform der 2>/dev/null 
        | openssl dgst -sha256 -hex 
        | sed "s/^.* //"'
}

get_token() {
    _ssh ${!master_nodes[@]} \
        'kubeadm token list -o json' | jq -r .token
}

declare -A master_nodes=([node0]=10.0.0.2)
declare -A worker_nodes=([node1]=10.0.0.3 [node2]=10.0.0.4)

main() {
    # for node in ${!master_nodes[@]} ${!worker_nodes[@]}; do echo $node; done \
    #     | xargs -P ${#nodes[@]} -I {} _vagrant up {} --provision


    [[ $1 == '-c' ]] && _vagrant destroy -f

    _vagrant up --provision # libvirtd supports parallel provisioning
    
    _vagrant ssh-config | tail -n +2     > ssh.conf

    init_cluster
    local hash=$(get_hash)
    local token=$(get_token)

    for node in ${!worker_nodes[@]}; do
        # _ssh $master 'sudo swapoff -a'
        _ssh $node \
            "sudo kubeadm join \
                ${master_nodes[@]}:6443 \
                --token=$token \
                --discovery-token-ca-cert-hash=sha256:$hash"
    done
}

set -x
main "$@"