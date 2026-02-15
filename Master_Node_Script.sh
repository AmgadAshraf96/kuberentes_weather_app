#!/bin/bash
#This script is for the master node.
# We will install containerD,kubernetescluster>
# Change the Masternode Hostname
sudo hostnamectl set-hostname master
sudo sed -i '/127.0.1.1/d' /etc/hosts
echo "127.0.1.1 master" | sudo tee -a /etc/hosts
# add dns server to master nodes it helps pods to resolve the ips of global dns names 
sudo bash -c 'cat > /etc/resolv.conf << EOF
nameserver 8.8.8.8
search members.linode.com
EOF'


# update APT Packages
sudo apt-get update -y
####################################################################################################################

# Allow APT to use HTTPS
sudo apt install apt-transport-https curl -y
####################################################################################################################
# uprade APT Packages
sudo apt-get upgrade -y

####################################################################################################################

# install containerD
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install containerd.io -y
#####################################################################################################################

#create the containerd configuration file using the following commands:
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml

#Edit /etc/containerd/config.toml
# Define the key and the new value
key="SystemdCgroup"
new_value="true"
sfile="/etc/containerd/config.toml"

    if grep -qi "^\s*${key}\s*=" "${sfile}"; then
        echo "The key is exist"
        sudo sed -i "s/^\(\s*${key}\s*=\s*\).*$/\1${new_value}/I" "${sfile}"
    else
        echo "the file is not exist"
       # echo "${key}=${new_value}" | sudo tee -a "${sfile}"
    fi
# Restart containerd:
sudo systemctl restart containerd
####################################################################################################################

#To disable swap on all the nodes using the following command.
sudo swapoff -a
(crontab -l 2>/dev/null; echo "@reboot /sbin/swapoff -a") | crontab - || true
#The fstab entry will make sure the swap is off on system reboots.
####################################################################################################################

#Enable kernel modules
sudo modprobe br_netfilter
echo "install modprobe"
#Add some settings to sysctl
sudo sysctl -w net.ipv4.ip_forward=1
####################################################################################################################
# This script for all nodes

# update APT Packages
sudo apt-get update
####################################################################################################################

# Add the new repository key:
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg

# Add the new repository:
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Install Kubernetes Components (kubelet, kubeadm, and kubectl):

sudo apt update
sudo apt install -y kubelet kubeadm kubectl

# This script for master nodes
##########################################################################################################################
# Disable swap again
sudo swapoff -a
# Install docker
sudo apt-get update
#Use the following command to initialize the cluster:
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
echo "cluster initialized"
#Create a .kube directory in your home directory:
mkdir -p $HOME/.kube

#Copy the Kubernetes configuration file to your home directory:
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config

#Change ownership of the file:
sudo chown $(id -u):$(id -g) $HOME/.kube/config
##########################################################################################################################

# Install calico addon
sudo kubectl apply -f calico-withnat.yaml
echo "calico installed"
##########################################################################################################################

# install helm on the master node
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4
chmod 700 get_helm.sh
./get_helm.sh

### THE NEXT PART IS FOR LINODE CLOUD ONLY !!!

# You MUST  allow IPENCAP protocol ON the linode Firewall for calico networking! 

#To install Linode Block Storage CSI Driver its important for persistent volume claim .
    # helm repo add linode-csi https://linode.github.io/linode-blockstorage-csi-driver/
    # helm repo update linode-csi
    # helm install linode-csi-driver linode-csi/linode-blockstorage-csi-driver \
    #--set apiToken=<linodeapitoken> \
    #--set region=<linoderegion> \
    #--namespace kube-system


# TO install CCM (The Cloud Controller Manager)Automatic provisioning of Linode NodeBalancers when you create LoadBalancer services:
    # Add the Linode Helm repository
        #helm repo add linode-ccm https://linode.github.io/linode-cloud-controller-manager/

    # Update the repository to get the latest charts
        #helm repo update

    # Now install the CCM
        #helm install ccm-linode linode-ccm/ccm-linode \
        #--set apiToken=<linodeapitoken> \
        #--set region=<linoderegion> \
        #--namespace kube-system \
        #--set linodegoDebug=true

###
# TO INSTALL NGNIX INGRESS controller
    #helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    #helm repo update
    #helm install nginx-ingress ingress-nginx/ingress-nginx \
    #--namespace ingress-nginx --create-namespace \
    #--set controller.kind=DaemonSet \
    #--set controller.service.type=LoadBalancer 
