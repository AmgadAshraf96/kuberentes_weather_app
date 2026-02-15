#!/bin/bash
# Essential Kubernetes Worker Node Installation Script

# 1. Update system
sudo apt-get update && sudo apt-get upgrade -y

# 2. Install prerequisites
sudo apt install apt-transport-https curl -y

# 3. Install containerd
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install containerd.io -y

# 4. Configure containerd with systemd cgroup
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd

# 5. Disable swap (Kubernetes requirement)
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# 6. Enable kernel modules
sudo modprobe br_netfilter
sudo modprobe overlay

# 7. Configure sysctl for Kubernetes networking
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sudo sysctl --system

# 8. Install Kubernetes components
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# 9. Enable kubelet
sudo systemctl enable kubelet

echo "✅ Worker node setup complete!"
echo "📋 Next step: Get the join command from master node and run it here"
echo ""
echo "On master node, run:"
echo "  kubeadm token create --print-join-command"