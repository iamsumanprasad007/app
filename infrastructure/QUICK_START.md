# 🚀 Quick Start Guide - TopList Kubernetes on AWS

## 📁 Project Structure Overview

```
infrastructure/
├── terraform/                          # Infrastructure as Code
│   ├── modules/
│   │   ├── vpc/                        # VPC, subnets, gateways
│   │   ├── security-groups/            # Security groups for K8s
│   │   └── ec2/                        # EC2 instances with K8s setup
│   ├── environments/dev/               # Environment-specific configs
│   └── scripts/                        # User data scripts
│       ├── master-userdata.sh          # K8s master setup
│       └── worker-userdata.sh          # K8s worker setup
└── kubernetes/                         # K8s application manifests
    ├── manifests/
    │   ├── namespace/                  # Namespaces
    │   ├── database/                   # PostgreSQL StatefulSet
    │   ├── backend/                    # Spring Boot deployment
    │   ├── frontend/                   # React deployment
    │   ├── ingress/                    # HAProxy ingress controller
    │   └── monitoring/                 # Prometheus monitoring
    └── configs/                        # Deployment scripts
        ├── build-images.sh             # Build Docker images
        ├── deploy.sh                   # Deploy to K8s
        └── setup-monitoring.sh         # Setup monitoring
```

## ⚡ One-Command Deployment

```bash
# 1. Configure AWS and create key pair
aws configure
aws ec2 create-key-pair --key-name k8s-cluster --query 'KeyMaterial' --output text > ~/.ssh/k8s-cluster.pem
chmod 400 ~/.ssh/k8s-cluster.pem

# 2. Deploy infrastructure
cd infrastructure/terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init && terraform apply -auto-approve

# 3. Build and deploy application
cd ../../../
./infrastructure/kubernetes/configs/build-images.sh
./infrastructure/kubernetes/configs/deploy.sh

# 4. Setup monitoring (optional)
./infrastructure/kubernetes/configs/setup-monitoring.sh
```

## 🎯 What Gets Deployed

### AWS Infrastructure
- ✅ **VPC** with public/private subnets across 2 AZs
- ✅ **Internet Gateway** and **NAT Gateways**
- ✅ **Security Groups** for K8s master and workers
- ✅ **EC2 Instances**: 1 master (t3.medium) + 2 workers (t3.small)
- ✅ **Application Load Balancer** for ingress traffic
- ✅ **S3 Bucket** for cluster coordination

### Kubernetes Cluster
- ✅ **Kubernetes 1.28** with kubeadm
- ✅ **Calico CNI** for pod networking
- ✅ **HAProxy Ingress Controller** for traffic routing
- ✅ **RBAC** enabled for security

### Application Stack
- ✅ **PostgreSQL StatefulSet** with persistent storage
- ✅ **Spring Boot Backend** (2 replicas)
- ✅ **React Frontend** (2 replicas) 
- ✅ **Ingress Rules** for routing
- ✅ **ConfigMaps** and **Secrets** for configuration

### Monitoring (Optional)
- ✅ **Prometheus** for metrics collection
- ✅ **Service Discovery** for automatic target detection
- ✅ **NodePort** access for monitoring dashboards

## 🌐 Access Points

After deployment, you can access:

```bash
# Get access information
terraform output

# Application via NodePort
http://<worker-ip>:30080

# Application via Load Balancer
http://<alb-dns-name>

# Prometheus Monitoring
http://<worker-ip>:30090

# Direct API access
http://<worker-ip>:30080/api/toplist
```

## 🔧 Key Features

### Infrastructure Features
- **High Availability**: Multi-AZ deployment
- **Security**: Private subnets, security groups, IAM roles
- **Scalability**: Auto Scaling Groups ready
- **Monitoring**: CloudWatch integration
- **Cost Optimized**: Right-sized instances

### Kubernetes Features
- **Production Ready**: RBAC, network policies, resource limits
- **Self-Healing**: Automatic pod restart and rescheduling
- **Rolling Updates**: Zero-downtime deployments
- **Service Discovery**: Automatic service registration
- **Load Balancing**: Built-in load balancing

### Application Features
- **Database Persistence**: PostgreSQL with persistent volumes
- **Configuration Management**: ConfigMaps and Secrets
- **Health Checks**: Liveness and readiness probes
- **Resource Management**: CPU and memory limits
- **Logging**: Centralized logging ready

## 📊 Resource Requirements

### Minimum Requirements
- **Master Node**: t3.medium (2 vCPU, 4GB RAM)
- **Worker Nodes**: 2x t3.small (2 vCPU, 2GB RAM each)
- **Storage**: 20GB per node + 10GB for database
- **Network**: VPC with internet access

### Estimated Costs (us-west-2)
- **EC2 Instances**: ~$70-100/month
- **Load Balancer**: ~$20/month
- **Storage**: ~$10/month
- **Data Transfer**: Variable
- **Total**: ~$100-130/month

## 🛠️ Customization Options

### Instance Types
```hcl
# In terraform.tfvars
master_instance_type = "t3.large"    # For higher workloads
worker_instance_type = "t3.medium"   # For more resources
worker_count = 3                     # Add more workers
```

### Network Configuration
```hcl
# Custom CIDR blocks
vpc_cidr = "172.16.0.0/16"
public_subnet_cidrs = ["172.16.1.0/24", "172.16.2.0/24"]
private_subnet_cidrs = ["172.16.10.0/24", "172.16.20.0/24"]
```

### Application Scaling
```bash
# Scale deployments
kubectl scale deployment toplist-backend --replicas=3 -n toplist
kubectl scale deployment toplist-frontend --replicas=3 -n toplist
```

## 🔍 Verification Commands

```bash
# Check infrastructure
terraform show
aws ec2 describe-instances --filters "Name=tag:Project,Values=TopList-K8s"

# Check Kubernetes cluster
kubectl get nodes
kubectl get pods --all-namespaces
kubectl get services --all-namespaces

# Check application
kubectl get pods -n toplist
curl http://<worker-ip>:30080/api/toplist

# Check monitoring
kubectl get pods -n monitoring
curl http://<worker-ip>:30090
```

## 🧹 Cleanup

```bash
# Destroy everything
cd infrastructure/terraform/environments/dev
terraform destroy -auto-approve

# Clean local files
rm ~/.kube/config
rm ~/.ssh/k8s-cluster.pem
docker rmi toplist-backend:latest toplist-frontend:latest
```

## 📚 Next Steps

1. **Custom Domain**: Configure Route53 and SSL certificates
2. **CI/CD Pipeline**: Set up GitHub Actions for automated deployments
3. **Monitoring**: Add Grafana dashboards and alerting
4. **Backup Strategy**: Implement database backups
5. **Security**: Add network policies and pod security policies
6. **Scaling**: Configure horizontal pod autoscaling

## 🆘 Support

- **Documentation**: See `DEPLOYMENT_GUIDE.md` for detailed instructions
- **Troubleshooting**: Check logs with `kubectl logs` commands
- **Monitoring**: Use Prometheus for metrics and alerting
- **Community**: Kubernetes and Terraform communities

---

**🎉 Congratulations! You now have a production-ready Kubernetes cluster running the TopList application on AWS!**
