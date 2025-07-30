#!/bin/bash

# KRO and Kargo Demo Cleanup Script

set -e

echo "🧹 Starting cleanup..."

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

# Stop port forwarding
print_status "Stopping port forwarding..."
pm2 stop all 2>/dev/null || true
pm2 delete all 2>/dev/null || true

# Delete ArgoCD applications
print_status "Deleting ArgoCD applications..."
kubectl delete -f argocd/nginx-app.yaml --ignore-not-found=true
kubectl delete -f argocd/nginx-app-staging.yaml --ignore-not-found=true
kubectl delete -f argocd/nginx-app-prod.yaml --ignore-not-found=true

# Delete Kargo resources
print_status "Deleting Kargo resources..."
kubectl delete -f kargo/stage-staging.yaml --ignore-not-found=true
kubectl delete -f kargo/stage-dev.yaml --ignore-not-found=true
kubectl delete -f kargo/warehouse.yaml --ignore-not-found=true
kubectl delete -f kargo/project.yaml --ignore-not-found=true

# Delete namespaces
print_status "Deleting application namespaces..."
kubectl delete namespace nginx-app-dev --ignore-not-found=true
kubectl delete namespace nginx-app-staging --ignore-not-found=true
kubectl delete namespace nginx-app-prod --ignore-not-found=true

print_status "Cleanup completed successfully!"
echo ""
echo "✅ All resources have been removed."
echo "📋 Remaining resources:"
echo "  • Kargo system resources (if you want to keep Kargo)"
echo "  • ArgoCD system resources (if you want to keep ArgoCD)"
echo ""
echo "🗑️  To remove Kargo completely: kubectl delete -f https://github.com/akuity/kargo/releases/latest/download/kargo.yaml"
echo "🗑️  To remove ArgoCD completely: kubectl delete -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
echo "" 