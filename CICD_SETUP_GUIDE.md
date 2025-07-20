# 🚀 CI/CD Setup Guide - GitHub Actions + Helm + Docker Hub

This comprehensive guide will help you set up the complete CI/CD pipeline for the TopList application with GitHub Actions, Docker Hub integration, security scanning, and Helm deployment.

## 📋 Prerequisites Checklist

### Required Accounts & Tools
- [ ] **GitHub Account** with repository access
- [ ] **Docker Hub Account** for container registry
- [ ] **Kubernetes Cluster** (local or cloud)
- [ ] **Helm 3.x** installed locally
- [ ] **kubectl** configured for your cluster

### Optional Security Tools
- [ ] **Snyk Account** for dependency scanning
- [ ] **Slack Workspace** for notifications

## 🔧 Step 1: GitHub Repository Setup

### 1.1 Repository Secrets Configuration

Navigate to your GitHub repository → Settings → Secrets and variables → Actions

**Required Secrets:**
```bash
# Docker Hub Integration
DOCKER_USERNAME=your-dockerhub-username
DOCKER_PASSWORD=your-dockerhub-password-or-token

# Kubernetes Cluster Access (for deployment)
KUBE_CONFIG_DEV=<base64-encoded-kubeconfig-for-dev>
KUBE_CONFIG_PROD=<base64-encoded-kubeconfig-for-prod>

# Optional: Security Scanning
SNYK_TOKEN=your-snyk-api-token

# Optional: Notifications
SLACK_WEBHOOK=your-slack-webhook-url
SECURITY_SLACK_WEBHOOK=your-security-slack-webhook-url
```

### 1.2 Get Base64 Encoded Kubeconfig

```bash
# For development cluster
cat ~/.kube/config | base64 -w 0

# For production cluster (if different)
cat ~/.kube/config-prod | base64 -w 0
```

### 1.3 Update Docker Hub Repository Names

Edit the following files and replace `your-dockerhub-username` with your actual Docker Hub username:

```bash
# Update in .github/workflows/ci-cd-pipeline.yml
BACKEND_IMAGE: your-dockerhub-username/toplist-backend
FRONTEND_IMAGE: your-dockerhub-username/toplist-frontend

# Update in helm/toplist-app/values.yaml
backend:
  image:
    repository: your-dockerhub-username/toplist-backend
frontend:
  image:
    repository: your-dockerhub-username/toplist-frontend
```

## 🐳 Step 2: Docker Hub Setup

### 2.1 Create Docker Hub Repositories

1. Login to [Docker Hub](https://hub.docker.com)
2. Create two repositories:
   - `your-username/toplist-backend`
   - `your-username/toplist-frontend`
3. Set both repositories to **Public** (or Private if you have a paid plan)

### 2.2 Generate Access Token

1. Go to Docker Hub → Account Settings → Security
2. Click "New Access Token"
3. Name: `github-actions-toplist`
4. Permissions: `Read, Write, Delete`
5. Copy the generated token (use this as `DOCKER_PASSWORD` secret)

## 🔒 Step 3: Security Tools Setup (Optional)

### 3.1 Snyk Setup

1. Sign up at [Snyk.io](https://snyk.io)
2. Go to Account Settings → API Token
3. Copy the token and add as `SNYK_TOKEN` secret

### 3.2 Slack Integration

1. Create a Slack App in your workspace
2. Add Incoming Webhooks
3. Create webhooks for:
   - `#deployments` channel → `SLACK_WEBHOOK`
   - `#security-alerts` channel → `SECURITY_SLACK_WEBHOOK`

## ⛵ Step 4: Helm Setup

### 4.1 Install Helm

```bash
# macOS
brew install helm

# Linux
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Windows
choco install kubernetes-helm
```

### 4.2 Add Required Repositories

```bash
# Add Bitnami repository for PostgreSQL
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

### 4.3 Validate Helm Charts

```bash
# Lint the chart
helm lint helm/toplist-app

# Template validation
helm template toplist helm/toplist-app --values helm/toplist-app/values.yaml

# Dry run
helm install toplist-test helm/toplist-app --values helm/toplist-app/values.yaml --dry-run
```

## 🚀 Step 5: Initial Deployment

### 5.1 Local Testing

```bash
# Build images locally (if you have the Kubernetes build script)
./infrastructure/kubernetes/configs/build-images.sh

# Tag and push to Docker Hub
docker tag toplist-backend:latest your-dockerhub-username/toplist-backend:latest
docker tag toplist-frontend:latest your-dockerhub-username/toplist-frontend:latest

docker push your-dockerhub-username/toplist-backend:latest
docker push your-dockerhub-username/toplist-frontend:latest
```

### 5.2 Deploy with Helm

```bash
# Development deployment
./helm/scripts/deploy-helm.sh dev

# Production deployment (if you have values-prod.yaml)
./helm/scripts/deploy-helm.sh prod
```

## 🔄 Step 6: CI/CD Pipeline Workflow

### 6.1 Workflow Triggers

The pipeline triggers on:
- **Push** to `main`, `master`, or `develop` branches
- **Pull Requests** to `main` or `master`
- **Manual trigger** via GitHub Actions UI

### 6.2 Pipeline Stages

1. **Backend Testing**
   - Unit tests with JUnit
   - Integration tests with PostgreSQL
   - Test report generation

2. **Frontend Testing**
   - ESLint code quality checks
   - Unit tests with Jest
   - Coverage reporting

3. **Security Scanning**
   - Trivy container vulnerability scanning
   - Snyk dependency scanning
   - CodeQL static analysis

4. **Docker Build & Push**
   - Multi-stage Docker builds
   - Image optimization
   - Push to Docker Hub with tags

5. **Helm Validation**
   - Chart linting
   - Template validation
   - Package creation

6. **Deployment** (on develop branch)
   - Automatic deployment to development
   - Health checks and verification

## 🧪 Step 7: Testing the Pipeline

### 7.1 Trigger the Pipeline

```bash
# Make a small change and push
echo "# CI/CD Test" >> README.md
git add README.md
git commit -m "test: trigger CI/CD pipeline"
git push origin main
```

### 7.2 Monitor the Pipeline

1. Go to GitHub → Actions tab
2. Watch the pipeline execution
3. Check each job's logs
4. Verify Docker images are pushed to Docker Hub

### 7.3 Verify Deployment

```bash
# Check Helm release
helm list -n toplist

# Check pods
kubectl get pods -n toplist

# Test application
kubectl port-forward service/toplist-frontend 3000:80 -n toplist
# Visit http://localhost:3000
```

## 🚨 Troubleshooting

### Common Issues

1. **Docker Push Fails**
   ```bash
   # Check Docker Hub credentials
   docker login
   # Verify repository names match
   ```

2. **Kubernetes Deployment Fails**
   ```bash
   # Check kubeconfig
   kubectl cluster-info
   # Verify namespace exists
   kubectl get namespaces
   ```

3. **Helm Chart Issues**
   ```bash
   # Debug template rendering
   helm template toplist helm/toplist-app --debug
   # Check values
   helm get values toplist -n toplist
   ```

4. **Security Scan Failures**
   ```bash
   # Check Trivy results
   trivy image your-dockerhub-username/toplist-backend:latest
   # Update base images for security fixes
   ```

## 🎯 Next Steps

1. **Set up monitoring** with Prometheus and Grafana
2. **Implement GitOps** with ArgoCD or Flux
3. **Add more environments** (staging, QA)
4. **Implement blue-green deployments**
5. **Set up automated testing** in different environments
6. **Add performance testing** to the pipeline

---

**🎉 Congratulations! You now have a complete CI/CD pipeline with GitHub Actions, Docker Hub, security scanning, and Helm deployment for your TopList application!**
