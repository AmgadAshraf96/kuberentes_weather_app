# kuberentes_weather_app
Weather microservices application deployed on Kubernetes with kubeadm cluster, Linode CSI Driver, CCM for LoadBalancer automation, and NGINX Ingress Controller. Demonstrates StatefulSets, Deployments, Services, and cloud-native practices.

**Infrastructure:**
  The application runs on a multi-node Kubernetes cluster deployed on **Linode Cloud**, providing real cloud infrastructure for production-like operations.

🏗️**Architecture**
**The application consists of four independent microservices:**
  * MySQL Database - Deployed as StatefulSet with persistent storage for user data
  * Authentication Service (Go) - Handles user registration, login, and session management
  * Weather Service (Python) - Integrates with external Weather API to fetch real-time data
  * UI Service (Node.js) - Frontend application coordinating user interactions

**Kubernetes Objects Used**
  * StatefulSet - For MySQL database with stable network identity and persistent storage
  * Deployments - For stateless microservices with rolling update strategies
  * Services (ClusterIP & Headless) - For internal service discovery
  * Ingress - For external HTTPS traffic routing
  * Secrets - For secure credential management
  * PersistentVolumeClaim - For database storage requirements
  * Job - For one-time database initialization

**Production Infrastructure Components:-**

**1. Kubeadm Cluster Setup**
  * Multi-node Kubernetes cluster (1 master, 2+ workers)
  * Container runtime: containerd
  * CNI Plugin: Calico for pod networking

**Project Structure:-**

  ├── Master_Node_Script.sh              # Master node setup automation
  |
  ├── Worker_Nodes_script.sh             # Worker nodes setup automation
  |
  ├── calico-withnat.yaml                # Calico CNI configuration
  |
  ├── kubernetes_files/
  │   ├── 1-mysql_creation/              # MySQL StatefulSet, Service, Job
  |
  │   ├── 2-auth/                        # Auth service Deployment & Service
  |
  │   ├── 3-weather/                     # Weather service Deployment & Service
  |
  │   └── 4-ui/                          # UI Deployment, Service & Ingress
  |
  └── project_files/
      ├── auth/                          # Go authentication service code
      |
      ├── weather/                       # Python weather service code
      |
      └── UI/                            # Node.js frontend code
      

**🛠️ Installation**
  1. Cluster Setup

    On Master Node:
      sudo bash Master_Node_Script.sh
      
    On Worker Nodes:
      sudo bash Worker_Nodes_script.sh
    # Run the join command on worker nodes
 
  3. Deploy Infrastructure Components

    # Install Linode CSI Driver
      helm repo add linode-csi https://linode.github.io/linode-blockstorage-csi-driver/
      helm repo update
      helm install linode-csi-driver linode-csi/linode-blockstorage-csi-driver \
        --set apiToken=<YOUR_LINODE_API_TOKEN> \
        --set region=<YOUR_REGION> \
        --namespace kube-system
        
    # Install Cloud Controller Manager
      helm repo add linode-ccm https://linode.github.io/linode-cloud-controller-manager/
      helm install ccm-linode linode-ccm/ccm-linode \
        --set apiToken=<YOUR_LINODE_API_TOKEN> \
        --set region=<YOUR_REGION> \
        --namespace kube-system
        
    # Install NGINX Ingress Controller
      helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
      helm install nginx-ingress ingress-nginx/ingress-nginx \
        --namespace ingress-nginx --create-namespace \
        --set controller.service.type=LoadBalancer
        
  3. Deploy Application
     
    # Step 1: Deploy MySQL
      kubectl apply -f kubernetes_files/1-mysql_creation/1-mysqlsecret.yaml
      kubectl apply -f kubernetes_files/1-mysql_creation/2-sqlservice.yaml
      kubectl apply -f kubernetes_files/1-mysql_creation/3-statfulset.yaml
      
    # Wait for MySQL to be ready
      kubectl wait --for=condition=ready pod -l app=mysqldbpod --timeout=300s
      
    # Initialize database
      kubectl apply -f kubernetes_files/1-mysql_creation/4-initjob.yaml
      
    # Step 2: Deploy Auth Service
      kubectl apply -f kubernetes_files/2-auth/
      
    # Step 3: Deploy Weather Service (update secret with your API key first)
      kubectl apply -f kubernetes_files/3-weather/
      
    # Step 4: Deploy UI Service
      kubectl apply -f kubernetes_files/4-ui/
  
  5. Configure Ingress
    # Create TLS secret (if using HTTPS)

      kubectl create secret tls uitlssecret \
        --cert=path/to/your/cert.crt \
        --key=path/to/your/key.key
     
    # Update domain in kubernetes_files/4-ui/3-all_ingress.yaml
    
    # Then apply
      kubectl apply -f kubernetes_files/4-ui/3-all_ingress.yaml
      
  **Verification**
    # Check all pods
      kubectl get pods
    
    # Check services
      kubectl get svc
    
    # Check ingress and get LoadBalancer IP
      kubectl get ingress
  
    # Check persistent volumes
      kubectl get pv,pvc
    
    # View logs
    kubectl logs <pod-name>
