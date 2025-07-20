#!/bin/bash

# Deploy TopList Application using Helm
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration
CHART_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/../toplist-app" && pwd)"
RELEASE_NAME="toplist"
NAMESPACE="toplist"
ENVIRONMENT=${1:-dev}
VALUES_FILE="values-${ENVIRONMENT}.yaml"

print_status "Deploying TopList application with Helm..."
print_status "Chart Path: $CHART_PATH"
print_status "Environment: $ENVIRONMENT"
print_status "Values File: $VALUES_FILE"

# Check if Helm is installed
if ! command -v helm &> /dev/null; then
    print_error "Helm is not installed. Please install Helm first."
    exit 1
fi

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed or not in PATH"
    exit 1
fi

# Check if cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to Kubernetes cluster. Please check your kubeconfig."
    exit 1
fi

# Check if values file exists
if [ ! -f "$CHART_PATH/$VALUES_FILE" ]; then
    print_warning "Values file $VALUES_FILE not found. Using default values.yaml"
    VALUES_FILE="values.yaml"
fi

# Add Bitnami repository for PostgreSQL
print_status "Adding Bitnami Helm repository..."
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Create namespace if it doesn't exist
print_status "Creating namespace $NAMESPACE..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Lint the Helm chart
print_status "Linting Helm chart..."
if ! helm lint $CHART_PATH --values $CHART_PATH/$VALUES_FILE; then
    print_error "Helm chart linting failed"
    exit 1
fi

# Template and validate
print_status "Validating Helm templates..."
helm template $RELEASE_NAME $CHART_PATH \
    --namespace $NAMESPACE \
    --values $CHART_PATH/$VALUES_FILE \
    --validate > /tmp/helm-template-output.yaml

print_success "Helm chart validation passed"

# Deploy or upgrade
print_status "Deploying application..."
helm upgrade --install $RELEASE_NAME $CHART_PATH \
    --namespace $NAMESPACE \
    --values $CHART_PATH/$VALUES_FILE \
    --wait \
    --timeout=15m \
    --create-namespace

if [ $? -eq 0 ]; then
    print_success "Deployment completed successfully!"
else
    print_error "Deployment failed!"
    exit 1
fi

# Show deployment status
print_status "Checking deployment status..."
echo ""
print_status "=== Helm Release Status ==="
helm status $RELEASE_NAME -n $NAMESPACE

echo ""
print_status "=== Kubernetes Resources ==="
kubectl get all -n $NAMESPACE

echo ""
print_status "=== Pod Status ==="
kubectl get pods -n $NAMESPACE -o wide

# Wait for pods to be ready
print_status "Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=$RELEASE_NAME -n $NAMESPACE --timeout=300s

# Get access information
echo ""
print_status "=== Access Information ==="

# Get NodePort information
if kubectl get service -n $NAMESPACE | grep -q NodePort; then
    NODEPORT_HTTP=$(kubectl get service -n $NAMESPACE -o jsonpath='{.items[?(@.spec.type=="NodePort")].spec.ports[?(@.name=="http")].nodePort}' | head -1)
    if [ ! -z "$NODEPORT_HTTP" ]; then
        print_status "NodePort HTTP: $NODEPORT_HTTP"
        
        # Get worker node IPs
        WORKER_IPS=$(kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="ExternalIP")].address}')
        if [ -z "$WORKER_IPS" ]; then
            WORKER_IPS=$(kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}')
        fi
        
        print_status "Worker Node IPs: $WORKER_IPS"
        echo ""
        
        for ip in $WORKER_IPS; do
            print_status "Application URL: http://$ip:$NODEPORT_HTTP"
        done
    fi
fi

# Get ingress information
INGRESS_HOST=$(kubectl get ingress -n $NAMESPACE -o jsonpath='{.items[0].spec.rules[0].host}' 2>/dev/null)
if [ ! -z "$INGRESS_HOST" ]; then
    print_status "Ingress Host: $INGRESS_HOST"
    print_status "Add to /etc/hosts: <node-ip> $INGRESS_HOST"
fi

echo ""
print_status "=== Useful Commands ==="
echo "helm status $RELEASE_NAME -n $NAMESPACE"
echo "kubectl get pods -n $NAMESPACE"
echo "kubectl logs -f deployment/$RELEASE_NAME-backend -n $NAMESPACE"
echo "kubectl logs -f deployment/$RELEASE_NAME-frontend -n $NAMESPACE"
echo "kubectl port-forward service/$RELEASE_NAME-frontend 3000:80 -n $NAMESPACE"
echo "kubectl port-forward service/$RELEASE_NAME-backend 8080:8080 -n $NAMESPACE"

echo ""
print_success "TopList application deployed successfully with Helm!"

# Optional: Run tests
if [ "$2" = "--test" ]; then
    print_status "Running Helm tests..."
    helm test $RELEASE_NAME -n $NAMESPACE
fi
