#!/bin/bash

# Kubernetes Worker Node Setup Script
set -e

# Variables
KUBERNETES_VERSION="1.28.0-00"

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

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

# Configure AWS CLI
mkdir -p /home/ubuntu/.aws
cat > /home/ubuntu/.aws/config <<EOF
[default]
region = ${aws_region}
output = json
EOF
chown -R ubuntu:ubuntu /home/ubuntu/.aws

# Wait for master node to be ready and join command to be available
echo "Waiting for master node to be ready..."
sleep 180

# Function to join cluster
join_cluster() {
    local max_attempts=10
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        echo "Attempt $attempt to join cluster..."
        
        # Try to get join command from S3
        if aws s3 cp s3://${cluster_name}-k8s-setup/kubeadm-join-command.sh /tmp/kubeadm-join-command.sh 2>/dev/null; then
            chmod +x /tmp/kubeadm-join-command.sh
            if /tmp/kubeadm-join-command.sh --cloud-provider=aws; then
                echo "Successfully joined cluster!"
                return 0
            fi
        fi
        
        echo "Join attempt $attempt failed, waiting 30 seconds..."
        sleep 30
        ((attempt++))
    done
    
    echo "Failed to join cluster after $max_attempts attempts"
    return 1
}

# Try to join the cluster
if join_cluster; then
    echo "Worker node successfully joined the cluster"
else
    echo "Failed to join cluster, will retry on next boot"
    # Create a systemd service to retry on boot
    cat > /etc/systemd/system/k8s-join-retry.service <<EOF
[Unit]
Description=Kubernetes Join Retry
After=network.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'sleep 60 && /tmp/kubeadm-join-command.sh --cloud-provider=aws'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
    systemctl enable k8s-join-retry.service
fi

# Setup kubectl for ubuntu user (in case this becomes a master later)
mkdir -p /home/ubuntu/.kube
chown ubuntu:ubuntu /home/ubuntu/.kube

# Create completion script
echo 'source <(kubectl completion bash)' >> /home/ubuntu/.bashrc
echo 'alias k=kubectl' >> /home/ubuntu/.bashrc
echo 'complete -F __start_kubectl k' >> /home/ubuntu/.bashrc

# Log completion
echo "Worker node setup completed at $(date)" >> /var/log/k8s-setup.log

echo "Kubernetes worker node setup completed!"
