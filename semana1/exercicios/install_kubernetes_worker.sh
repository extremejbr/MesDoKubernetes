
echo "Processo de instalação e configuração do Worker Kubernete"
echo "#########################################################"
echo ""
echo "*Script criado por Jones Radtke"
echo "V0.0.1"
echo "11/01/24"
echo ""
echo ""

echo "--> Iniciando configurações..."

echo "Desativando o uso do swap no sistema"
sudo swapoff -a

echo "Carregando os módulos do kernel"
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

echo "--> Configurando parâmetros do sistema"
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system

echo "--> Instalando os pacotes do Kubernetes"
sudo apt-get update && sudo apt-get install -y apt-transport-https curl

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl

sudo apt-mark hold kubelet kubeadm kubectl

echo "--> Instalando o containerd"
sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update && sudo apt-get install -y containerd.io

echo "--> Configurando o containerd"
sudo mkdir /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml

sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

sudo systemctl restart containerd
sudo systemctl status containerd

echo "--> Habilitando o serviço do kubelet"
sudo systemctl enable --now kubelet

echo ""
echo ""
echo "--> Adicionando o worker ao Cluster"
echo "###################################"
kubeadm join 192.168.242.201:6443 --token tl3e4g.tk80uaozs9321g9s \
        --discovery-token-ca-cert-hash sha256:3a123d3d70aa5d13ebdaa39f44ce58f245ec7e78e745c7b94647dc9db0ed82d7