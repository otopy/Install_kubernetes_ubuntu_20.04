# install Kubernetes (Установка Kubernetes)
![Alt-текст](https://hsto.org/getpro/habr/post_images/6ea/1b1/d57/6ea1b1d575af9daaec0e0b095cc88420.jpg)
Установка Kubernetes - Kubeadm, Kubelet, Kubectl

В данном примере рассмотрим установку Kubernetes на машины с OS Ubuntu. До пункта "Установка Kubernetes" действия производятся одинаково как на master ноде так и на worker нодах.  


## Исходные данные
|РОЛЬ|FQDN|IP|OS|RAM|CPU|
|----|----|----|----|----|----|
|Master|master.example.com|192.168.99.100|Ubuntu 20.04|2G|2|
|Worker|worker1.example.com|192.168.99.101|Ubuntu 20.04|4G|2|
|Worker|worker2.example.com|192.168.99.102|Ubuntu 20.04|4G|2|

## Установка runtime

На выбор мы можем установить 1 из 3х runtime 

1. Docker
2. CRI-O
3. Containerd

Выбрать при установке можно только 1 из них.

### Docker

Добавляем репозиторий и устанавливаем пакеты.

```console
sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common ipvsadm
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
sudo apt update
sudo apt install -y containerd.io docker-ce docker-ce-cli
```

Запускаем сервис докера

```console
sudo systemctl daemon-reload 
sudo systemctl restart docker
sudo systemctl enable docker
```

### CRI-O

Загружаем необходимые модули

```console
sudo tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter
```

Устанавливаем необходимые параметры sysctl

```console
sudo tee /etc/sysctl.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
```

Перезагружаем sysctl

```console
sudo sysctl --system
```

Добавляем репозиторий 

```console
sudo sh -c "echo 'deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_20.04/ /' > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list"
wget -nv https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/xUbuntu_20.04/Release.key -O- | sudo apt-key add -
sudo apt update
```

Устанавливаем CRI-O

```console
sudo apt install -y cri-o-1.17 ipvsadm
```

Запускаем сервис CRI-O

```console
sudo systemctl daemon-reload
sudo systemctl start crio
sudo systemctl enable crio
```

### Containerd

Загружаем необходимые модули

```console
sudo tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter
```

Устанавливаем необходимые параметры sysctl

```console
sudo tee /etc/sysctl.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
```

Перезагружаем sysctl

```console
sudo sysctl --system
```

Добавляем репозиторий и устанавливаем пакеты.

```console
sudo apt install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common ipvsadm
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
sudo apt update
sudo apt install -y containerd.io
```

Настраиваем и запускаем сервис

```console
sudo mkdir -p /etc/containerd
sudo su -
containerd config default  /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd
```

## Отключаем swap и фаервол

Отключаем swap

```console
sudo swapoff -a
sudo sed -i '/swap/d' /etc/fstab
```

Отключаем фаервол

```console
sudo ufw disable
```

## Установка компонентов Kubernetes

Добавляем репозиторий

```console
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
```

Устанавливаем компоненты

```console
sudo apt-get install -y kubelet=1.19.4-00 kubeadm=1.19.4-00 kubectl=1.19.4-00
sudo apt-mark hold docker-ce kubelet kubeadm kubectl
sudo systemctl enable kubelet.service

```

## Установка Kubernetes master

Действия производятся на мастер ноде... 
Запустим инициализацию мастер ноды. 
```console
sudo kubeadm config images pull
sudo kubeadm init \
  --pod-network-cidr=192.168.0.0/16 \
  --apiserver-advertise-address=192.168.99.100
```

После установки мастер ноды заберем конфиг фаил и посмотрим на наш кластер

```console
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
kubectl get nodes
```

Установим Calico network 

```console
kubectl apply -f https://docs.projectcalico.org/v3.14/manifests/calico.yaml
```

Для получения команды на подключения ноды выполните команду 

```console
kubeadm token create --print-join-command
```

Полученные данные Выполняем на нодах кластера

## Установка Kubernetes worker

Для добавления ноды в кластер выполните команду полученную на предыдущем шаге при установке master ноды в виде sudo kubeadm join $controller_private_ip:6443 --token $token --discovery-token-ca-cert-hash $hash
Пример:

```console
sudo kubeadm join 192.168.99.100:6443 --token Ibinjde862123eK --discovery-token-ca-cert-hash sha256:2nr1jr41fbhb32rdc89fer3o4fn23f23rf3ewseqcewx
```

