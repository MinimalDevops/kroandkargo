#!/bin/bash

# Create Namespaces Script

echo "🏗️  Creating required namespaces..."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Create kargo namespace
print_status "Creating kargo namespace..."
kubectl create namespace kargo --dry-run=client -o yaml | kubectl apply -f -

# Create argocd namespace
print_status "Creating argocd namespace..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# Create application namespaces
print_status "Creating application namespaces..."
kubectl create namespace nginx-app-dev --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace nginx-app-staging --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace nginx-app-prod --dry-run=client -o yaml | kubectl apply -f -

print_status "All namespaces created successfully!"
echo ""
echo "📋 Created namespaces:"
echo "  • kargo"
echo "  • argocd"
echo "  • nginx-app-dev"
echo "  • nginx-app-staging"
echo "  • nginx-app-prod"
echo ""
echo "✅ You can now proceed with deploying Kargo and ArgoCD resources." 