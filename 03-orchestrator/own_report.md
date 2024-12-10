# Building K8s


## Building the Platform Together

We initially set up the clusters manually, documenting all the steps as we went along. Afterward, we converted those steps into an Ansible script for automation.
The repository for the Ansible scripts can be found [here](https://github.com/Soldatstar/HS24-Cloud/tree/main/03-orchestrator)

---

## Building a K3s Cluster

### Initializing the K3s Server Node
* Step: Initializing the first K3s server with --cluster-init.
* What: The first server is initialized as the control-plane node, but the cluster is not yet formed.
* Solved via: 
`curl -sfL https://get.k3s.io | K3S_TOKEN=SECRET sh -s - server \ --cluster-init`

### Joining the Cluster on the Worker Node
* Step: Adding a worker node to the K3s cluster.
* What: The second server is intended to join the cluster as a worker node, but requires the server URL and valid token for authentication.
* Solved via: 
`curl -sfL https://get.k3s.io | K3S_TOKEN=SECRET sh -s - server \ --server https://10.0.2.35:6443`

---

## Building a Kubernetes (K8s) Cluster

For this step, we followed the O'Reilly documentation as a primary resource,
supplemented by additional online sources like [this guide](https://devopsquare.com/how-to-create-kubernetes-cluster-with-containerd-90399ec3b810).
Since the repository we initially used was deprecated, I switched to using the official Kubernetes repository for the setup process.

## Install Kubernetes Tools (`kubelet`, `kubeadm`, `kubectl`) [Our Ansible Script](https://github.com/Soldatstar/HS24-Cloud/blob/main/03-orchestrator/ansible/k8s_install_kubeTools.yml)

```bash
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl
sudo curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```

---

## Install and Configure `containerd` [Our Ansible Script](https://github.com/Soldatstar/HS24-Cloud/blob/main/03-orchestrator/ansible/k8s_install_container_runtime.yml)

```bash
sudo apt-get update
sudo apt-get install -y containerd
sudo modprobe overlay
sudo modprobe br_netfilter
sudo tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd
```

---

## Set Up Kubernetes Master Node 

This task was done in 2 parts, one with a single master node and one with a HA setup.
The HA setup was done with 2 master nodes and a loadbalancer in front of them.
The loadbalancer was set up with haproxy.

### [Our Ansible Script for Task 2](https://github.com/Soldatstar/HS24-Cloud/blob/main/03-orchestrator/ansible/k8s_init_master_join_worker.yml)

### [Our Ansible Script for Task 3](https://github.com/Soldatstar/HS24-Cloud/blob/main/03-orchestrator/ansible/k8s_init_HA_and_join.yml)

```bash
sudo sysctl net.ipv4.ip_forward=1
sudo kubeadm reset -f
sudo curl https://haproxy.debian.net/bernat.debian.org.gpg | gpg --dearmor -o /usr/share/keyrings/haproxy.debian.net.gpg
echo "deb [signed-by=/usr/share/keyrings/haproxy.debian.net.gpg] http://haproxy.debian.net bookworm-backports-3.0 main" | sudo tee /etc/apt/sources.list.d/haproxy.list
sudo apt-get update
sudo apt-get install -y haproxy=3.0.*
```
copying our pre setup haproxy.cfg. it listens on port 6444 and forwards to the apiservers on port 6443. It runs on k8smain01.
```
frontend kubernetes-api
    bind {{ hostvars['k8smain01'].private_ip }}:6444
    default_backend apiservers

backend apiservers
    balance roundrobin
    server k8smain01 {{ hostvars['k8smain01'].private_ip }}:6443 check
    server k8smain02 {{ hostvars['k8smain02'].private_ip }}:6443 check
```

```bash
sudo systemctl restart haproxy
sudo systemctl enable haproxy
sudo kubeadm init --control-plane-endpoint "<private_ip>:6443" --upload-certs --pod-network-cidr=192.168.0.0/16
```

---

## Set Up Kubernetes Config and Networking. IP Forwarding and iptables

```bash
mkdir -p $HOME/.kube
 cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

sudo tee /etc/sysctl.d/99-kubernetes-cri.conf <<EOF
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sudo sysctl --system
sudo update-alternatives --config iptables
```

---

## Install Calico Networking

```bash
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.0/manifests/tigera-operator.yaml
wget https://raw.githubusercontent.com/projectcalico/calico/v3.29.0/manifests/custom-resources.yaml -O /tmp/custom-resources.yaml
kubectl create -f /tmp/custom-resources.yaml
```

---

## Join Worker Nodes to Kubernetes

```bash
sudo kubeadm reset -f
sudo kubeadm join <master_ip>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>
```

---

## Join a Second Control Plane Node to Kubernetes

for this step we had to research how to get a new token, because we wanted to automatize the process with ansible. we came across the following [command](https://stackoverflow.com/a/71831186) on Stackoverflow:
```bash        
echo $(kubeadm token create --print-join-command) --control-plane --certificate-key $(kubeadm init phase upload-certs --upload-certs | grep -vw -e certificate -e Namespace)
```

after that, we only have to join the new control plane node with the resulting output.

## Start an Example Workload and Check the Cluster

```bash
kubectl create deployment hello-node --image=registry.k8s.io/echoserver:1.4
kubectl get pods -o wide
kubectl get pods -n kube-system
kubectl get pods -n calico-system
kubectl get nodes
```

## Technical problems and solutions

### Setting up HAProxy as loadbalancer
* Step: When Setting up the loadbalancer, i defined *:6444 as the bind adress.
* What: the kubeadm command always failed: "sudo kubeadm init --control-plane-endpoint "10.0.4.5:6444" --upload-certs"
* Solved via: setting the actual IP 10.0.4.5:6444 as bind adress fixed this issue. Seems like it didn't bind to the private interface when left with *.

## Personal reflection

### Damjan

* **Workload-1: K3s Cluster installation**
  - I've learned how easy it is to set up a cluster using the Kubernetes distribution K3s. I mark the first node as the Control-Plane and  define a token that allows Worker Nodes to join the cluster. These Worker Nodes also need the IP address of the Control-Plane. Afterward, I can use kubectl to orchestrate containers as if it were a K8s cluster.

* **Workload-2: Difference between K3s and K8s**
  - K3s is a simplified version of K8s. It consumes fewer resources, making it suitable for running clusters on devices like IoT devices. K3s reduces complexity by removing some features of Kubernetes, such as the complex etcd cluster. Instead, it uses a simplified database solution called Cluster Datastore.

* **Workload-3: Define Control-Plane for K3s**
  - To prevent Pods from being scheduled on the control plane, this node must be marked with a taint. This influences the scheduler and prevents Pods from being scheduled on the node.  

### Viktor

* **Workload-1: Containerd and Kubernetes**
  - Configuring Containerd to work seamlessly with Kubernetes involved several critical steps:
    I had to create the necessary directories and generate the default configuration file.
    Then, I modified the config.toml file to set SystemdCgroup to true. Then I Restarted and enabled the Containerd service. On first try I also had to initialize the kubeadm with the flag  --cri-socket /run/containerd/containerd.sock


* **Workload-2: Networking & CNI Plugin**
  - Setting up networking with Calico was tricky.
    I didn’t realize how complicated Kubernetes networking is.
    I had to make sure that pods could communicate across nodes and services were discoverable. 


* **Workload-3: Setting Up a Load Balancer**
  - Setting up the load balancer was harder than expected.
    I had to learn how Kubernetes services work with load balancers like HAProxy.
    The main challenge was configuring it to listen to correct addresses and forward traffic to the right ports.


