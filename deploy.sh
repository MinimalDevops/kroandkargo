#!/bin/bash

# KRO and Kargo Demo Deployment Script

set -e

echo "🚀 Starting KRO and Kargo Demo Deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
print_status "Checking prerequisites..."

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed. Please install kubectl first."
    exit 1
fi

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    print_error "helm is not installed. Please install helm first."
    exit 1
fi

# Check if pm2 is installed
if ! command -v pm2 &> /dev/null; then
    print_warning "pm2 is not installed. Installing pm2..."
    npm install -g pm2
fi

# Check if we can connect to the cluster
if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to Kubernetes cluster. Please check your kubectl configuration."
    exit 1
fi

print_status "Prerequisites check passed!"

# Create required namespaces
print_status "Creating required namespaces..."

# Create kargo namespace if it doesn't exist
if ! kubectl get namespace kargo &> /dev/null; then
    print_status "Creating kargo namespace..."
    kubectl create namespace kargo
else
    print_status "kargo namespace already exists."
fi

# Create argocd namespace if it doesn't exist
if ! kubectl get namespace argocd &> /dev/null; then
    print_status "Creating argocd namespace..."
    kubectl create namespace argocd
else
    print_status "argocd namespace already exists."
fi

# Create application namespaces
print_status "Creating application namespaces..."

kubectl create namespace nginx-app-dev --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace nginx-app-staging --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace nginx-app-prod --dry-run=client -o yaml | kubectl apply -f -

print_status "All namespaces created successfully!"

# Repository configuration
print_status "Using repository: https://github.com/MinimalDevops/kroandkargo.git"
print_status "All configuration files are pre-configured for this repository."

# Deploy Kargo resources
print_status "Deploying Kargo resources..."

print_status "Applying Kargo project..."
kubectl apply -f kargo/project.yaml

print_status "Applying Kargo warehouse..."
kubectl apply -f kargo/warehouse.yaml

print_status "Applying Kargo stages..."
kubectl apply -f kargo/stage-dev.yaml
kubectl apply -f kargo/stage-staging.yaml

# Deploy ArgoCD applications for all environments
print_status "Deploying ArgoCD applications..."

print_status "Applying ArgoCD application for dev environment..."
kubectl apply -f argocd/nginx-app.yaml

print_status "Applying ArgoCD application for staging environment..."
kubectl apply -f argocd/nginx-app-staging.yaml

print_status "Applying ArgoCD application for production environment..."
kubectl apply -f argocd/nginx-app-prod.yaml

# Wait for resources to be ready
print_status "Waiting for resources to be ready..."

# Wait for Kargo warehouse
print_status "Waiting for Kargo warehouse..."
kubectl wait --for=condition=Ready warehouse/nginx-warehouse -n nginx-demo --timeout=60s

# Wait for Kargo stages
print_status "Waiting for Kargo stages..."
kubectl wait --for=condition=Ready stage/dev -n nginx-demo --timeout=60s
kubectl wait --for=condition=Ready stage/staging -n nginx-demo --timeout=60s

# Wait for ArgoCD applications
print_status "Waiting for ArgoCD applications..."
kubectl wait --for=condition=Healthy application/nginx-app-dev -n argocd --timeout=60s
kubectl wait --for=condition=Healthy application/nginx-app-staging -n argocd --timeout=60s
kubectl wait --for=condition=Healthy application/nginx-app-prod -n argocd --timeout=60s

# Trigger initial sync if needed
print_status "Triggering initial sync for ArgoCD applications..."
kubectl patch application nginx-app-dev -n argocd --type='merge' -p='{"metadata":{"annotations":{"argocd.argoproj.io/sync-wave":"0"}}}' 2>/dev/null || true
kubectl patch application nginx-app-staging -n argocd --type='merge' -p='{"metadata":{"annotations":{"argocd.argoproj.io/sync-wave":"0"}}}' 2>/dev/null || true
kubectl patch application nginx-app-prod -n argocd --type='merge' -p='{"metadata":{"annotations":{"argocd.argoproj.io/sync-wave":"0"}}}' 2>/dev/null || true

print_status "All resources deployed successfully!"

# Start port forwarding
print_status "Starting port forwarding with PM2..."

# Stop any existing port forwards
pm2 stop all 2>/dev/null || true
pm2 delete all 2>/dev/null || true

# Start new port forwards
pm2 start ecosystem.config.js

print_status "Port forwarding started!"

# Display access information
echo ""
echo "🎉 Deployment completed successfully!"
echo ""
echo "📋 Access Information:"
echo "  • ArgoCD: https://localhost:5003/applications"
echo "  • Kargo: https://localhost:5004/"
echo ""
echo "🔑 ArgoCD Admin Password:"
echo "  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
echo ""
echo "📊 Check Status:"
echo "  • Kargo stages: kubectl get stages -n nginx-demo"
echo "  • ArgoCD apps: kubectl get application -n argocd"
echo "  • Dev app: kubectl get all -n nginx-app-dev"
echo "  • Staging app: kubectl get all -n nginx-app-staging"
echo "  • Prod app: kubectl get all -n nginx-app-prod"
echo ""
echo "🛑 To stop port forwarding: pm2 stop all"
echo "🗑️  To cleanup: ./cleanup.sh"
echo "" 