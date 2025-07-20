#!/bin/bash

# Deploy TopList Application to Kubernetes
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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
NAMESPACE="toplist"
MANIFESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../manifests" && pwd)"

print_status "Deploying TopList application to Kubernetes..."
print_status "Manifests directory: $MANIFESTS_DIR"

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

print_success "Connected to Kubernetes cluster"

# Function to wait for deployment
wait_for_deployment() {
    local deployment=$1
    local namespace=$2
    local timeout=${3:-300}
    
    print_status "Waiting for deployment $deployment in namespace $namespace..."
    if kubectl wait --for=condition=available --timeout=${timeout}s deployment/$deployment -n $namespace; then
        print_success "Deployment $deployment is ready"
        return 0
    else
        print_error "Deployment $deployment failed to become ready within ${timeout}s"
        return 1
    fi
}

# Function to wait for statefulset
wait_for_statefulset() {
    local statefulset=$1
    local namespace=$2
    local timeout=${3:-300}
    
    print_status "Waiting for statefulset $statefulset in namespace $namespace..."
    if kubectl wait --for=condition=ready --timeout=${timeout}s pod -l app=$statefulset -n $namespace; then
        print_success "StatefulSet $statefulset is ready"
        return 0
    else
        print_error "StatefulSet $statefulset failed to become ready within ${timeout}s"
        return 1
    fi
}

# Deploy in order
print_status "Step 1: Creating namespaces..."
kubectl apply -f $MANIFESTS_DIR/namespace/
sleep 5

print_status "Step 2: Deploying HAProxy Ingress Controller..."
kubectl apply -f $MANIFESTS_DIR/ingress/haproxy-ingress-controller.yaml
sleep 10

print_status "Step 3: Deploying database..."
kubectl apply -f $MANIFESTS_DIR/database/
sleep 10

# Wait for PostgreSQL to be ready
wait_for_statefulset "postgresql" $NAMESPACE 300

print_status "Step 4: Deploying backend..."
kubectl apply -f $MANIFESTS_DIR/backend/
sleep 10

# Wait for backend to be ready
wait_for_deployment "toplist-backend" $NAMESPACE 300

print_status "Step 5: Deploying frontend..."
kubectl apply -f $MANIFESTS_DIR/frontend/
sleep 10

# Wait for frontend to be ready
wait_for_deployment "toplist-frontend" $NAMESPACE 300

print_status "Step 6: Deploying ingress..."
kubectl apply -f $MANIFESTS_DIR/ingress/toplist-ingress.yaml
sleep 5

# Check deployment status
print_status "Checking deployment status..."

echo ""
print_status "=== Deployment Status ==="
kubectl get pods -n $NAMESPACE
echo ""
kubectl get services -n $NAMESPACE
echo ""
kubectl get ingress -n $NAMESPACE
echo ""

# Get ingress controller service
print_status "=== Ingress Controller ==="
kubectl get service -n haproxy-controller
echo ""

# Get node ports
NODEPORT_HTTP=$(kubectl get service haproxy-ingress -n haproxy-controller -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}')
NODEPORT_HTTPS=$(kubectl get service haproxy-ingress -n haproxy-controller -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')

print_success "Deployment completed successfully!"
echo ""
print_status "=== Access Information ==="
print_status "NodePort HTTP: $NODEPORT_HTTP"
print_status "NodePort HTTPS: $NODEPORT_HTTPS"
echo ""

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

echo ""
print_status "=== Useful Commands ==="
echo "kubectl get pods -n $NAMESPACE"
echo "kubectl logs -f deployment/toplist-backend -n $NAMESPACE"
echo "kubectl logs -f deployment/toplist-frontend -n $NAMESPACE"
echo "kubectl logs -f deployment/haproxy-ingress -n haproxy-controller"
echo ""

# Optional: Port forward for local access
if [ "$1" = "--port-forward" ]; then
    print_status "Setting up port forwarding..."
    print_status "Frontend will be available at http://localhost:3000"
    print_status "Backend will be available at http://localhost:8080"
    print_status "Press Ctrl+C to stop port forwarding"
    
    kubectl port-forward service/toplist-frontend 3000:80 -n $NAMESPACE &
    kubectl port-forward service/toplist-backend 8080:8080 -n $NAMESPACE &
    
    wait
fi
