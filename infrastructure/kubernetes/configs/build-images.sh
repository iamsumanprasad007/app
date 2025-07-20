#!/bin/bash

# Build Docker Images for Kubernetes Deployment
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
BACKEND_IMAGE="toplist-backend:latest"
FRONTEND_IMAGE="toplist-frontend:latest"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../" && pwd)"

print_status "Building Docker images for Kubernetes deployment..."
print_status "Project root: $PROJECT_ROOT"

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker first."
    exit 1
fi

# Build Backend Image
print_status "Building backend image: $BACKEND_IMAGE"
cd "$PROJECT_ROOT"

if [ ! -f "pom.xml" ]; then
    print_error "pom.xml not found in project root. Please run this script from the correct location."
    exit 1
fi

# Create Dockerfile for backend if it doesn't exist
if [ ! -f "Dockerfile.k8s-backend" ]; then
    print_status "Creating Dockerfile for backend..."
    cat > Dockerfile.k8s-backend <<EOF
# Multi-stage Dockerfile for Kubernetes Backend
FROM maven:latest AS build
WORKDIR /app
COPY pom.xml ./
COPY src ./src
RUN mvn clean package -DskipTests

FROM openjdk:17-jdk-slim
WORKDIR /app

# Install curl for health checks
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Copy the built jar
COPY --from=build /app/target/*.jar app.jar

# Create non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser
RUN chown appuser:appuser /app
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/actuator/health || exit 1

EXPOSE 8080
CMD ["java", "-jar", "app.jar"]
EOF
fi

docker build -f Dockerfile.k8s-backend -t $BACKEND_IMAGE .
if [ $? -eq 0 ]; then
    print_success "Backend image built successfully: $BACKEND_IMAGE"
else
    print_error "Failed to build backend image"
    exit 1
fi

# Build Frontend Image
print_status "Building frontend image: $FRONTEND_IMAGE"
cd "$PROJECT_ROOT/frontend"

if [ ! -f "package.json" ]; then
    print_error "package.json not found in frontend directory."
    exit 1
fi

# Create Dockerfile for frontend if it doesn't exist
if [ ! -f "Dockerfile.k8s-frontend" ]; then
    print_status "Creating Dockerfile for frontend..."
    cat > Dockerfile.k8s-frontend <<EOF
# Multi-stage Dockerfile for Kubernetes Frontend
FROM node:18-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build

FROM nginx:alpine
# Install curl for health checks
RUN apk add --no-cache curl

# Copy built frontend
COPY --from=build /app/build /usr/share/nginx/html

# Copy nginx configuration (will be overridden by ConfigMap in K8s)
COPY --from=build /app/build /usr/share/nginx/html

# Create non-root user
RUN addgroup -g 1001 -S nginx && \
    adduser -S -D -H -u 1001 -h /var/cache/nginx -s /sbin/nologin -G nginx -g nginx nginx

# Set permissions
RUN chown -R nginx:nginx /usr/share/nginx/html && \
    chown -R nginx:nginx /var/cache/nginx && \
    chown -R nginx:nginx /var/log/nginx && \
    chown -R nginx:nginx /etc/nginx/conf.d
RUN touch /var/run/nginx.pid && \
    chown -R nginx:nginx /var/run/nginx.pid

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:80/ || exit 1

USER nginx
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF
fi

docker build -f Dockerfile.k8s-frontend -t $FRONTEND_IMAGE .
if [ $? -eq 0 ]; then
    print_success "Frontend image built successfully: $FRONTEND_IMAGE"
else
    print_error "Failed to build frontend image"
    exit 1
fi

# List built images
print_status "Built images:"
docker images | grep -E "(toplist-backend|toplist-frontend)"

print_success "All images built successfully!"
print_status "You can now deploy to Kubernetes using:"
print_status "  kubectl apply -f ../manifests/"

# Optional: Save images to tar files for transfer
if [ "$1" = "--save" ]; then
    print_status "Saving images to tar files..."
    docker save $BACKEND_IMAGE -o toplist-backend.tar
    docker save $FRONTEND_IMAGE -o toplist-frontend.tar
    print_success "Images saved to tar files"
fi

# Optional: Load images to kind cluster
if [ "$1" = "--kind" ]; then
    print_status "Loading images to kind cluster..."
    kind load docker-image $BACKEND_IMAGE
    kind load docker-image $FRONTEND_IMAGE
    print_success "Images loaded to kind cluster"
fi
