#!/bin/bash

# TopList Application Build Script

echo "🚀 Building TopList Application..."

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

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    print_warning "Docker Compose is not installed. Using docker compose instead."
    DOCKER_COMPOSE_CMD="docker compose"
else
    DOCKER_COMPOSE_CMD="docker-compose"
fi

# Build options
case "${1:-help}" in
    "single")
        print_status "Building single container application..."
        docker build -t toplist-app .
        if [ $? -eq 0 ]; then
            print_success "Single container build completed!"
            echo ""
            echo "To run the application:"
            echo "  docker run -p 80:80 -p 8080:8080 toplist-app"
            echo ""
            echo "Access the application at: http://localhost"
        else
            print_error "Build failed!"
            exit 1
        fi
        ;;
    "compose")
        print_status "Building with Docker Compose..."
        $DOCKER_COMPOSE_CMD build
        if [ $? -eq 0 ]; then
            print_success "Docker Compose build completed!"
            echo ""
            echo "To start the application:"
            echo "  $DOCKER_COMPOSE_CMD up"
            echo ""
            echo "Services will be available at:"
            echo "  Frontend: http://localhost:3000"
            echo "  Backend:  http://localhost:8080"
        else
            print_error "Build failed!"
            exit 1
        fi
        ;;
    "dev")
        print_status "Starting development environment..."
        $DOCKER_COMPOSE_CMD up --build
        ;;
    "clean")
        print_status "Cleaning up Docker resources..."
        docker system prune -f
        docker volume prune -f
        print_success "Cleanup completed!"
        ;;
    "test")
        print_status "Running tests..."
        
        # Backend tests
        print_status "Running backend tests..."
        ./mvnw test
        
        # Frontend tests (if frontend directory exists)
        if [ -d "frontend" ]; then
            print_status "Running frontend tests..."
            cd frontend
            npm test -- --coverage --watchAll=false
            cd ..
        fi
        
        print_success "Tests completed!"
        ;;
    "help"|*)
        echo "TopList Application Build Script"
        echo ""
        echo "Usage: $0 [COMMAND]"
        echo ""
        echo "Commands:"
        echo "  single    Build single container (production)"
        echo "  compose   Build with Docker Compose (development)"
        echo "  dev       Start development environment"
        echo "  test      Run all tests"
        echo "  clean     Clean up Docker resources"
        echo "  help      Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0 single     # Build production container"
        echo "  $0 compose    # Build development setup"
        echo "  $0 dev        # Start development environment"
        ;;
esac
