#!/bin/bash
sudo apt update

sudo tee /etc/sysctl.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sudo apt install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common ipvsadm
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt install -y containerd.io docker-ce docker-ce-cli

sudo systemctl daemon-reload 
sudo systemctl restart docker
sudo systemctl enable docker

sudo swapoff -a
sudo sed -i '/swap/d' /etc/fstab

sudo ufw disable

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get install -y kubelet=1.19.4-00 kubeadm=1.19.4-00 kubectl=1.19.4-00
sudo apt-mark hold docker-ce kubelet kubeadm kubectl
sudo systemctl enable kubelet.service
