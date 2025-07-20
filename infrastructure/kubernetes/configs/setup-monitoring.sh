#!/bin/bash

# Setup Monitoring Stack for TopList Application
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

MANIFESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../manifests" && pwd)"

print_status "Setting up monitoring stack..."

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed or not in PATH"
    exit 1
fi

# Deploy Prometheus
print_status "Deploying Prometheus..."
kubectl apply -f $MANIFESTS_DIR/monitoring/prometheus.yaml

# Wait for Prometheus to be ready
print_status "Waiting for Prometheus to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/prometheus -n monitoring

print_success "Monitoring stack deployed successfully!"

# Get access information
PROMETHEUS_NODEPORT=$(kubectl get service prometheus -n monitoring -o jsonpath='{.spec.ports[0].nodePort}')
WORKER_IPS=$(kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="ExternalIP")].address}')

if [ -z "$WORKER_IPS" ]; then
    WORKER_IPS=$(kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}')
fi

echo ""
print_success "Monitoring stack is ready!"
print_status "=== Access Information ==="
print_status "Prometheus NodePort: $PROMETHEUS_NODEPORT"

for ip in $WORKER_IPS; do
    print_status "Prometheus URL: http://$ip:$PROMETHEUS_NODEPORT"
done

echo ""
print_status "=== Useful Queries ==="
echo "up - Check which targets are up"
echo "rate(http_requests_total[5m]) - HTTP request rate"
echo "container_memory_usage_bytes - Memory usage"
echo "container_cpu_usage_seconds_total - CPU usage"

echo ""
print_status "=== Port Forward (Alternative Access) ==="
echo "kubectl port-forward service/prometheus 9090:9090 -n monitoring"
echo "Then access: http://localhost:9090"
