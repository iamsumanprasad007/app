# 🚀 Complete Deployment Guide - TopList Kubernetes Infrastructure

This guide provides step-by-step instructions for deploying the TopList application on AWS using Terraform and Kubernetes.

## 📋 Prerequisites Checklist

### Required Tools
- [ ] **AWS CLI** configured with appropriate permissions
- [ ] **Terraform** >= 1.0 installed
- [ ] **kubectl** installed
- [ ] **Docker** installed and running
- [ ] **SSH key pair** created in AWS

### AWS Permissions Required
Your AWS user/role needs the following permissions:
- EC2 (full access)
- VPC (full access)
- IAM (create roles and policies)
- S3 (create and manage buckets)
- Route53 (if using custom domain)
- Application Load Balancer

## 🔧 Step-by-Step Deployment

### Step 1: Prepare AWS Environment

```bash
# Configure AWS CLI
aws configure
# Enter your Access Key ID, Secret Access Key, Region, and Output format

# Verify AWS configuration
aws sts get-caller-identity

# Create SSH key pair
aws ec2 create-key-pair --key-name k8s-cluster --query 'KeyMaterial' --output text > ~/.ssh/k8s-cluster.pem
chmod 400 ~/.ssh/k8s-cluster.pem
```

### Step 2: Clone and Configure

```bash
# Clone the repository
git clone <your-repo-url>
cd infrastructure/terraform/environments/dev

# Copy and configure variables
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values
vim terraform.tfvars
```

**Example terraform.tfvars:**
```hcl
aws_region = "us-west-2"
key_name = "k8s-cluster"
cluster_name = "toplist-k8s"
environment = "dev"

# Instance types
master_instance_type = "t3.medium"
worker_instance_type = "t3.small"

# Network configuration
vpc_cidr = "10.0.0.0/16"
public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]

# Optional: Custom domain
# domain_name = "yourdomain.com"
```

### Step 3: Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Plan the deployment (review changes)
terraform plan

# Apply the infrastructure
terraform apply

# Note: This will take 10-15 minutes
# The script will automatically:
# - Create VPC, subnets, security groups
# - Launch EC2 instances
# - Install Docker, Kubernetes, Calico CNI
# - Configure the cluster
```

### Step 4: Verify Kubernetes Cluster

```bash
# Get the master node IP
MASTER_IP=$(terraform output -raw master_public_ip)

# SSH to master node
ssh -i ~/.ssh/k8s-cluster.pem ubuntu@$MASTER_IP

# Check cluster status
kubectl get nodes
kubectl get pods --all-namespaces

# Exit from master node
exit
```

### Step 5: Configure Local kubectl

```bash
# Copy kubeconfig from master node
scp -i ~/.ssh/k8s-cluster.pem ubuntu@$MASTER_IP:/home/ubuntu/.kube/config ~/.kube/config

# Verify local kubectl access
kubectl get nodes
```

### Step 6: Build Application Images

```bash
# Navigate to project root
cd ../../../

# Build Docker images
./infrastructure/kubernetes/configs/build-images.sh

# Verify images are built
docker images | grep toplist
```

### Step 7: Transfer Images to Cluster

```bash
# Save images to tar files
docker save toplist-backend:latest -o toplist-backend.tar
docker save toplist-frontend:latest -o toplist-frontend.tar

# Transfer to master node
scp -i ~/.ssh/k8s-cluster.pem toplist-backend.tar ubuntu@$MASTER_IP:/tmp/
scp -i ~/.ssh/k8s-cluster.pem toplist-frontend.tar ubuntu@$MASTER_IP:/tmp/

# SSH to master and load images
ssh -i ~/.ssh/k8s-cluster.pem ubuntu@$MASTER_IP

# Load images on master
docker load -i /tmp/toplist-backend.tar
docker load -i /tmp/toplist-frontend.tar

# Transfer images to worker nodes
for worker_ip in $(kubectl get nodes -o jsonpath='{.items[?(@.metadata.name!="'$(hostname)'")].status.addresses[?(@.type=="InternalIP")].address}'); do
    echo "Transferring images to $worker_ip"
    scp /tmp/toplist-backend.tar ubuntu@$worker_ip:/tmp/
    scp /tmp/toplist-frontend.tar ubuntu@$worker_ip:/tmp/
    ssh ubuntu@$worker_ip "docker load -i /tmp/toplist-backend.tar && docker load -i /tmp/toplist-frontend.tar"
done

# Exit from master node
exit
```

### Step 8: Deploy Application

```bash
# Deploy the application
./infrastructure/kubernetes/configs/deploy.sh

# Monitor deployment progress
kubectl get pods -n toplist -w
```

### Step 9: Access the Application

```bash
# Get worker node IPs and NodePort
WORKER_IPS=$(kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="ExternalIP")].address}')
NODEPORT=$(kubectl get service haproxy-ingress -n haproxy-controller -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}')

echo "Application URLs:"
for ip in $WORKER_IPS; do
    echo "http://$ip:$NODEPORT"
done

# Or use ALB DNS name
ALB_DNS=$(terraform output -raw load_balancer_dns)
echo "ALB URL: http://$ALB_DNS"
```

## 🔍 Verification Steps

### 1. Check Infrastructure
```bash
# Verify all resources are created
terraform show

# Check EC2 instances
aws ec2 describe-instances --filters "Name=tag:Project,Values=TopList-K8s"
```

### 2. Check Kubernetes Cluster
```bash
# Verify nodes are ready
kubectl get nodes

# Check system pods
kubectl get pods -n kube-system

# Verify Calico is running
kubectl get pods -n calico-system
```

### 3. Check Application
```bash
# Verify all pods are running
kubectl get pods -n toplist

# Check services
kubectl get services -n toplist

# Check ingress
kubectl get ingress -n toplist

# Test backend API
kubectl port-forward service/toplist-backend 8080:8080 -n toplist &
curl http://localhost:8080/api/toplist
```

## 🐛 Troubleshooting

### Common Issues

#### 1. Nodes Not Joining Cluster
```bash
# Check master node logs
ssh -i ~/.ssh/k8s-cluster.pem ubuntu@$MASTER_IP
sudo journalctl -u kubelet -f

# Check worker node logs
ssh -i ~/.ssh/k8s-cluster.pem ubuntu@$WORKER_IP
sudo journalctl -u kubelet -f

# Regenerate join command
sudo kubeadm token create --print-join-command
```

#### 2. Pods Not Starting
```bash
# Check pod status
kubectl describe pod <pod-name> -n toplist

# Check logs
kubectl logs <pod-name> -n toplist

# Check node resources
kubectl describe nodes
```

#### 3. Images Not Found
```bash
# Verify images are loaded on all nodes
kubectl get nodes -o wide
# SSH to each node and run: docker images | grep toplist
```

#### 4. Database Connection Issues
```bash
# Check PostgreSQL pod
kubectl logs postgresql-0 -n toplist

# Test database connection
kubectl exec -it postgresql-0 -n toplist -- psql -U toplist -d toplistdb -c "\dt"
```

### Useful Commands

```bash
# Get all resources in namespace
kubectl get all -n toplist

# Describe problematic resources
kubectl describe deployment toplist-backend -n toplist

# Check events
kubectl get events -n toplist --sort-by='.lastTimestamp'

# Port forward for debugging
kubectl port-forward service/toplist-frontend 3000:80 -n toplist
kubectl port-forward service/toplist-backend 8080:8080 -n toplist

# Scale deployments
kubectl scale deployment toplist-backend --replicas=3 -n toplist

# Update images
kubectl set image deployment/toplist-backend toplist-backend=toplist-backend:v2 -n toplist
```

## 🧹 Cleanup

### Destroy Infrastructure
```bash
# Navigate to terraform directory
cd infrastructure/terraform/environments/dev

# Destroy all resources
terraform destroy

# Confirm with 'yes' when prompted
```

### Clean Local Environment
```bash
# Remove kubeconfig
rm ~/.kube/config

# Remove SSH key
rm ~/.ssh/k8s-cluster.pem

# Remove Docker images
docker rmi toplist-backend:latest toplist-frontend:latest
```

## 📊 Monitoring and Maintenance

### Regular Checks
- Monitor cluster health: `kubectl get nodes`
- Check resource usage: `kubectl top nodes`
- Review logs: `kubectl logs -f deployment/toplist-backend -n toplist`
- Verify backups: Check PostgreSQL data persistence

### Updates
- Update Kubernetes: Use kubeadm upgrade
- Update applications: Build new images and update deployments
- Update infrastructure: Modify Terraform and apply changes

## 🎯 Next Steps

1. **Set up monitoring** with Prometheus and Grafana
2. **Configure SSL/TLS** with cert-manager
3. **Implement CI/CD** with GitHub Actions
4. **Set up backup strategy** for PostgreSQL
5. **Configure autoscaling** for applications
6. **Implement logging** with ELK stack

This completes the deployment guide. Your TopList application should now be running on a production-ready Kubernetes cluster on AWS!
