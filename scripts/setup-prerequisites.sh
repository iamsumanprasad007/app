#!/bin/bash

# Prerequisites Setup Script for TopList CI/CD Pipeline
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

print_header() {
    echo ""
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""
}

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        if command -v apt-get &> /dev/null; then
            DISTRO="ubuntu"
        elif command -v yum &> /dev/null; then
            DISTRO="centos"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        OS="windows"
    else
        OS="unknown"
    fi
    
    print_status "Detected OS: $OS"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install Docker
install_docker() {
    print_header "Installing Docker"
    
    if command_exists docker; then
        print_success "Docker is already installed"
        docker --version
        return
    fi
    
    case $OS in
        "linux")
            if [ "$DISTRO" = "ubuntu" ]; then
                print_status "Installing Docker on Ubuntu..."
                sudo apt-get update
                sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
                curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
                echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
                sudo apt-get update
                sudo apt-get install -y docker-ce docker-ce-cli containerd.io
                sudo usermod -aG docker $USER
            fi
            ;;
        "macos")
            print_status "Installing Docker on macOS..."
            if command_exists brew; then
                brew install --cask docker
            else
                print_error "Please install Homebrew first or download Docker Desktop manually"
                return 1
            fi
            ;;
        *)
            print_error "Please install Docker manually for your OS"
            return 1
            ;;
    esac
    
    print_success "Docker installed successfully"
}

# Install kubectl
install_kubectl() {
    print_header "Installing kubectl"
    
    if command_exists kubectl; then
        print_success "kubectl is already installed"
        kubectl version --client
        return
    fi
    
    case $OS in
        "linux")
            print_status "Installing kubectl on Linux..."
            curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
            sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
            rm kubectl
            ;;
        "macos")
            print_status "Installing kubectl on macOS..."
            if command_exists brew; then
                brew install kubectl
            else
                curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/amd64/kubectl"
                chmod +x kubectl
                sudo mv kubectl /usr/local/bin/
            fi
            ;;
        *)
            print_error "Please install kubectl manually for your OS"
            return 1
            ;;
    esac
    
    print_success "kubectl installed successfully"
}

# Install Helm
install_helm() {
    print_header "Installing Helm"
    
    if command_exists helm; then
        print_success "Helm is already installed"
        helm version
        return
    fi
    
    case $OS in
        "linux")
            print_status "Installing Helm on Linux..."
            curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
            ;;
        "macos")
            print_status "Installing Helm on macOS..."
            if command_exists brew; then
                brew install helm
            else
                curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
            fi
            ;;
        *)
            print_error "Please install Helm manually for your OS"
            return 1
            ;;
    esac
    
    print_success "Helm installed successfully"
}

# Setup Helm repositories
setup_helm_repos() {
    print_header "Setting up Helm Repositories"
    
    print_status "Adding Bitnami repository..."
    helm repo add bitnami https://charts.bitnami.com/bitnami
    
    print_status "Adding Prometheus Community repository..."
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    
    print_status "Adding Ingress NGINX repository..."
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    
    print_status "Updating Helm repositories..."
    helm repo update
    
    print_success "Helm repositories configured successfully"
}

# Validate installations
validate_installations() {
    print_header "Validating Installations"
    
    local errors=0
    
    if ! command_exists docker; then
        print_error "Docker is not installed or not in PATH"
        ((errors++))
    else
        print_success "Docker: $(docker --version)"
    fi
    
    if ! command_exists kubectl; then
        print_error "kubectl is not installed or not in PATH"
        ((errors++))
    else
        print_success "kubectl: $(kubectl version --client --short)"
    fi
    
    if ! command_exists helm; then
        print_error "Helm is not installed or not in PATH"
        ((errors++))
    else
        print_success "Helm: $(helm version --short)"
    fi
    
    if [ $errors -eq 0 ]; then
        print_success "All prerequisites are installed successfully!"
        return 0
    else
        print_error "$errors prerequisite(s) failed to install"
        return 1
    fi
}

# Main installation function
main() {
    print_header "TopList CI/CD Prerequisites Setup"
    
    detect_os
    
    if [ "$OS" = "unknown" ]; then
        print_error "Unsupported operating system"
        exit 1
    fi
    
    # Install prerequisites
    install_docker
    install_kubectl
    install_helm
    
    # Setup Helm repositories
    setup_helm_repos
    
    # Validate installations
    if validate_installations; then
        print_header "Setup Complete!"
        print_success "All prerequisites have been installed successfully."
        echo ""
        print_status "Next steps:"
        echo "1. Configure Docker Hub credentials in GitHub Secrets"
        echo "2. Set up Kubernetes cluster access"
        echo "3. Update Docker Hub repository names in configuration files"
        echo "4. Run the CI/CD pipeline"
        echo ""
        print_status "For detailed setup instructions, see: CICD_SETUP_GUIDE.md"
    else
        print_error "Some prerequisites failed to install. Please check the errors above."
        exit 1
    fi
}

# Run main function
main "$@"
