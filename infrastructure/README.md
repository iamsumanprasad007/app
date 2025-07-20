# Kubernetes Infrastructure on AWS with Terraform

This repository contains Terraform modules to provision a Kubernetes cluster on AWS with 1 master node and 2 worker nodes, along with Kubernetes application deployment manifests.

## 📁 Project Structure

```
infrastructure/
├── terraform/
│   ├── modules/
│   │   ├── vpc/
│   │   ├── security-groups/
│   │   ├── ec2/
│   │   └── outputs/
│   ├── environments/
│   │   └── dev/
│   └── scripts/
└── kubernetes/
    ├── manifests/
    │   ├── namespace/
    │   ├── database/
    │   ├── backend/
    │   ├── frontend/
    │   └── ingress/
    └── configs/
```

## 🚀 Quick Start

### Prerequisites

1. **AWS CLI configured** with appropriate permissions
2. **Terraform** >= 1.0 installed
3. **kubectl** installed
4. **SSH key pair** created in AWS

### Step 1: Infrastructure Deployment

```bash
# Clone and navigate to terraform directory
cd infrastructure/terraform/environments/dev

# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the infrastructure
terraform apply
```

### Step 2: Kubernetes Setup

The infrastructure will automatically:
- ✅ Install Docker, kubeadm, kubelet, kubectl
- ✅ Initialize Kubernetes cluster with kubeadm
- ✅ Install Calico CNI
- ✅ Join worker nodes to the cluster
- ✅ Install HAProxy Ingress Controller

### Step 3: Application Deployment

```bash
# Get kubeconfig from master node
terraform output kubeconfig_command

# Apply application manifests
cd ../../kubernetes
kubectl apply -f manifests/
```

## 🏗️ Infrastructure Components

### AWS Resources Created

- **VPC** with public/private subnets across 2 AZs
- **Internet Gateway** and **NAT Gateway**
- **Security Groups** for master and worker nodes
- **EC2 Instances** (1 master + 2 workers)
- **Application Load Balancer** for ingress
- **Route53** DNS records (optional)

### Kubernetes Components

- **Kubernetes 1.28** cluster with kubeadm
- **Calico CNI** for networking
- **HAProxy Ingress Controller**
- **PostgreSQL StatefulSet** for database
- **TopList Application** deployment
- **NodePort Services** and **Ingress** resources

## 📋 Detailed Setup Instructions

### 1. AWS Prerequisites

```bash
# Configure AWS CLI
aws configure

# Create SSH key pair
aws ec2 create-key-pair --key-name k8s-cluster --query 'KeyMaterial' --output text > ~/.ssh/k8s-cluster.pem
chmod 400 ~/.ssh/k8s-cluster.pem
```

### 2. Terraform Variables

Create `terraform.tfvars`:

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
```

### 3. Deploy Infrastructure

```bash
cd infrastructure/terraform/environments/dev

# Initialize and apply
terraform init
terraform plan
terraform apply -auto-approve
```

### 4. Verify Kubernetes Cluster

```bash
# SSH to master node
ssh -i ~/.ssh/k8s-cluster.pem ubuntu@$(terraform output master_public_ip)

# Check cluster status
kubectl get nodes
kubectl get pods --all-namespaces
```

### 5. Deploy Applications

```bash
# From your local machine
cd infrastructure/kubernetes

# Apply all manifests
kubectl apply -f manifests/namespace/
kubectl apply -f manifests/database/
kubectl apply -f manifests/backend/
kubectl apply -f manifests/frontend/
kubectl apply -f manifests/ingress/
```

## 🔧 Configuration Details

### Master Node Configuration
- **Instance Type**: t3.medium (2 vCPU, 4GB RAM)
- **OS**: Ubuntu 20.04 LTS
- **Components**: kubeadm, kubelet, kubectl, Docker, Calico CNI

### Worker Node Configuration
- **Instance Type**: t3.small (2 vCPU, 2GB RAM)
- **OS**: Ubuntu 20.04 LTS
- **Components**: kubeadm, kubelet, Docker

### Network Configuration
- **CNI**: Calico with IPIP encapsulation
- **Pod CIDR**: 192.168.0.0/16
- **Service CIDR**: 10.96.0.0/12

## 🌐 Application Access

After deployment, access the application:

- **Frontend**: http://toplist.your-domain.com
- **Backend API**: http://toplist.your-domain.com/api
- **Ingress Controller**: NodePort on worker nodes

## 📊 Monitoring and Troubleshooting

### Check Cluster Health
```bash
kubectl get nodes
kubectl get pods --all-namespaces
kubectl describe nodes
```

### View Logs
```bash
kubectl logs -n kube-system -l k8s-app=calico-node
kubectl logs -n haproxy-controller -l run=haproxy-ingress
```

### Common Issues
1. **Nodes not joining**: Check security groups and network connectivity
2. **Pods not starting**: Verify CNI installation and node resources
3. **Ingress not working**: Check HAProxy controller and service endpoints

## 🔄 Cleanup

```bash
# Destroy infrastructure
cd infrastructure/terraform/environments/dev
terraform destroy -auto-approve
```

## 🔧 Advanced Configuration

### Custom Domain Setup
```bash
# Update terraform.tfvars
domain_name = "yourdomain.com"

# After deployment, update DNS records
# Point your domain to the ALB DNS name
```

### SSL/TLS Configuration
```bash
# Add SSL certificate to ALB
# Update ingress with TLS configuration
# Configure cert-manager for automatic certificates
```

### Monitoring Setup
```bash
# Deploy Prometheus and Grafana
kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/bundle.yaml

# Deploy monitoring stack
kubectl apply -f monitoring/
```

### Backup Configuration
```bash
# Setup PostgreSQL backups
# Configure persistent volume snapshots
# Implement disaster recovery procedures
```

## 📊 Cost Optimization

### Instance Sizing
- **Master Node**: t3.medium ($30-40/month)
- **Worker Nodes**: 2x t3.small ($20-30/month each)
- **Total Estimated Cost**: $70-100/month

### Cost Reduction Tips
1. Use Spot Instances for worker nodes
2. Schedule cluster shutdown for non-production
3. Implement cluster autoscaling
4. Use reserved instances for production

## 🚨 Security Best Practices

### Network Security
- Private subnets for worker nodes
- Security groups with minimal required ports
- VPC flow logs enabled
- WAF integration with ALB

### Kubernetes Security
- RBAC enabled by default
- Network policies with Calico
- Pod security policies
- Secrets encryption at rest

### Monitoring and Alerting
- CloudWatch integration
- Kubernetes events monitoring
- Application performance monitoring
- Security scanning with tools like Falco

## 📚 Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Calico Documentation](https://docs.projectcalico.org/)
- [HAProxy Ingress Controller](https://haproxy-ingress.github.io/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
