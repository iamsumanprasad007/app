#!/bin/bash

# Kubernetes Master Node Setup Script
set -e

# Variables
KUBERNETES_VERSION="1.28.0-00"
CALICO_VERSION="v3.26.1"
POD_CIDR="192.168.0.0/16"

# Update system
apt-get update
apt-get upgrade -y

# Install required packages
apt-get install -y apt-transport-https ca-certificates curl software-properties-common

# Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io

# Configure Docker daemon
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

mkdir -p /etc/systemd/system/docker.service.d
systemctl daemon-reload
systemctl restart docker
systemctl enable docker

# Add ubuntu user to docker group
usermod -aG docker ubuntu

# Disable swap
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Install Kubernetes components
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF

apt-get update
apt-get install -y kubelet=$KUBERNETES_VERSION kubeadm=$KUBERNETES_VERSION kubectl=$KUBERNETES_VERSION
apt-mark hold kubelet kubeadm kubectl

# Configure kubelet
cat > /etc/default/kubelet <<EOF
KUBELET_EXTRA_ARGS=--cloud-provider=aws
EOF

# Enable and start kubelet
systemctl enable kubelet

# Configure containerd
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd

# Initialize Kubernetes cluster
kubeadm init \
  --pod-network-cidr=$POD_CIDR \
  --cloud-provider=aws \
  --v=5

# Setup kubectl for ubuntu user
mkdir -p /home/ubuntu/.kube
cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
chown ubuntu:ubuntu /home/ubuntu/.kube/config

# Setup kubectl for root user
export KUBECONFIG=/etc/kubernetes/admin.conf
echo 'export KUBECONFIG=/etc/kubernetes/admin.conf' >> /root/.bashrc

# Install Calico CNI
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/$CALICO_VERSION/manifests/tigera-operator.yaml

# Wait for tigera-operator to be ready
sleep 30

# Create Calico custom resource
cat <<EOF | kubectl apply -f -
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  calicoNetwork:
    ipPools:
    - blockSize: 26
      cidr: $POD_CIDR
      encapsulation: IPIP
      natOutgoing: Enabled
      nodeSelector: all()
EOF

# Wait for Calico to be ready
sleep 60

# Install HAProxy Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/haproxytech/kubernetes-ingress/master/deploy/haproxy-ingress.yaml

# Create join command file
kubeadm token create --print-join-command > /tmp/kubeadm-join-command.sh
chmod +x /tmp/kubeadm-join-command.sh

# Save join command to S3 (if bucket exists)
if aws s3 ls s3://${cluster_name}-k8s-setup 2>/dev/null; then
    aws s3 cp /tmp/kubeadm-join-command.sh s3://${cluster_name}-k8s-setup/
fi

# Install AWS CLI if not present
if ! command -v aws &> /dev/null; then
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install
fi

# Configure AWS CLI for ubuntu user
mkdir -p /home/ubuntu/.aws
cat > /home/ubuntu/.aws/config <<EOF
[default]
region = ${aws_region}
output = json
EOF
chown -R ubuntu:ubuntu /home/ubuntu/.aws

# Create completion script
echo 'source <(kubectl completion bash)' >> /home/ubuntu/.bashrc
echo 'alias k=kubectl' >> /home/ubuntu/.bashrc
echo 'complete -F __start_kubectl k' >> /home/ubuntu/.bashrc

# Log completion
echo "Master node setup completed at $(date)" >> /var/log/k8s-setup.log

# Wait for all system pods to be ready
kubectl wait --for=condition=Ready pods --all -n kube-system --timeout=300s

echo "Kubernetes master node setup completed successfully!"
