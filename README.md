# KRO and Kargo Demo Project

This project demonstrates a complete GitOps workflow using:
- **KRO (Kubernetes Resource Overlays)** for environment-specific configurations
- **Kargo** for progressive delivery across environments
- **ArgoCD** for application state management
- **Helm** for templating and deployment

## Project Structure

```
.
├── helm-chart/                   # Helm chart for nginx
│   ├── Chart.yaml
│   ├── values.yaml               # base values
│   └── templates/
│       ├── _helpers.tpl
│       ├── deployment.yaml
│       ├── service.yaml
│       └── serviceaccount.yaml
├── overlays/
│   ├── dev/
│   │   └── values.yaml           # replicaCount: 1, image: nginx:alpine
│   ├── staging/
│   │   └── values.yaml           # replicaCount: 1, image: nginx:stable
│   └── prod/
│       └── values.yaml           # replicaCount: 1, image: nginx:stable
├── kro.yaml                      # Krofile listing the overlays
├── kargo/
│   ├── project.yaml              # Kargo Project
│   ├── warehouse.yaml            # Git source config
│   ├── stage-dev.yaml            # Dev stage
│   └── stage-staging.yaml        # Staging stage
├── argocd/
│   ├── nginx-app.yaml            # ArgoCD Application for dev
│   ├── nginx-app-staging.yaml    # ArgoCD Application for staging
│   └── nginx-app-prod.yaml       # ArgoCD Application for prod
├── ecosystem.config.js           # PM2 port forwarding config
├── deploy.sh                     # Automated deployment script
├── cleanup.sh                    # Cleanup script
├── test-helm.sh                  # Helm chart validation
└── README.md
```

## Prerequisites

- Kubernetes cluster (local or remote)
- ArgoCD installed and running on port 5003
- Kargo installed and running on port 5004
- KRO installed locally
- kubectl configured
- helm installed

## Setup Instructions

### 1. Repository Configuration

This project is configured to use the existing repository at [https://github.com/MinimalDevops/kroandkargo](https://github.com/MinimalDevops/kroandkargo).

All configuration files are already set up to use this repository URL:
- `kargo/warehouse.yaml`
- `kargo/stage-dev.yaml`
- `kargo/stage-staging.yaml`
- `argocd/nginx-app.yaml`
- `argocd/nginx-app-staging.yaml`
- `argocd/nginx-app-prod.yaml`

### 2. Create Required Namespaces

Before deploying, you need to create the required namespaces:

```bash
# Option 1: Use the automated script
./create-namespaces.sh

# Option 2: Manual creation
kubectl create namespace kargo
kubectl create namespace argocd
kubectl create namespace nginx-app-dev
kubectl create namespace nginx-app-staging
kubectl create namespace nginx-app-prod
```

### 3. Deploy Kargo Resources

```bash
# Apply Kargo project
kubectl apply -f kargo/project.yaml

# Apply warehouse
kubectl apply -f kargo/warehouse.yaml

# Apply stages
kubectl apply -f kargo/stage-dev.yaml
kubectl apply -f kargo/stage-staging.yaml
```

### 4. Deploy ArgoCD Applications

```bash
# Apply ArgoCD applications for all environments
kubectl apply -f argocd/nginx-app.yaml
kubectl apply -f argocd/nginx-app-staging.yaml
kubectl apply -f argocd/nginx-app-prod.yaml
```

**Note**: The ArgoCD applications include a `sync-wave: "0"` annotation to ensure proper initial synchronization. This helps resolve the "Unknown" sync status issue that can occur with automated sync policies.

### 5. Port Forwarding Setup

Use PM2 to manage port forwards:

```bash
# Install PM2 if not already installed
npm install -g pm2

# Create ecosystem file for port forwarding
cat > ecosystem.config.js << EOF
module.exports = {
  apps: [
    {
      name: 'argocd-port-forward',
      script: 'kubectl',
      args: 'port-forward -n argocd svc/argocd-server 5003:443',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '1G'
    },
    {
      name: 'kargo-port-forward',
      script: 'kubectl',
      args: 'port-forward -n kargo-system svc/kargo-api 5004:80',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '1G'
    }
  ]
};
EOF

# Start port forwarding
pm2 start ecosystem.config.js
```

### 6. Access the Applications

- **ArgoCD**: https://localhost:5003/applications
  - Username: admin
  - Password: Get from `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`

- **Kargo**: https://localhost:5004/

## How It Works

### 1. KRO Overlays
- **dev**: 1 replica, nginx:alpine image, no resource limits
- **staging**: 1 replica, nginx:stable image, no resource limits
- **prod**: 1 replica, nginx:stable image, no resource limits

### 2. Environment Separation
Each environment runs in its own namespace:
- **dev**: `nginx-app-dev`
- **staging**: `nginx-app-staging`
- **prod**: `nginx-app-prod`

### 3. Kargo Progressive Delivery
- **Warehouse**: Monitors changes in `overlays/dev`, `helm-chart`, and `kro.yaml`
- **Dev Stage**: Automatically promotes changes from warehouse
- **Staging Stage**: Promotes changes from dev stage after approval

### 4. ArgoCD Integration
- Manages the application state for each environment
- Syncs changes automatically
- Provides GitOps workflow visualization

## Testing the Setup

### 1. Make a Change to Dev Environment

```bash
# Update dev overlay
echo "replicaCount: 1" > overlays/dev/values.yaml

# Commit and push
git add overlays/dev/values.yaml
git commit -m "Update dev configuration"
git push origin main
```

### 2. Monitor the Flow

1. **Kargo Warehouse** detects the change
2. **Dev Stage** automatically promotes the change
3. **Staging Stage** can be manually promoted
4. **ArgoCD** syncs the application state for each environment

### 3. Check Application Status

```bash
# Check Kargo stages
kubectl get stages -n kargo-system

# Check ArgoCD applications
kubectl get application -n argocd

# Check deployed resources in each environment
kubectl get all -n nginx-app-dev
kubectl get all -n nginx-app-staging
kubectl get all -n nginx-app-prod
```

## Environment Promotion

To promote from dev to staging:

```bash
# Using Kargo CLI
kargo promote staging --project nginx-demo

# Or via Kargo UI at https://localhost:5004/
```

## Troubleshooting

### Common Issues

1. **Repository URL Issues**: Ensure all repository URLs are updated to your actual repository
2. **Namespace Issues**: Make sure namespaces exist or are created automatically
3. **Port Forward Issues**: Check if ports 5003 and 5004 are available

### Useful Commands

```bash
# Check Kargo status
kubectl get warehouse,stage -n nginx-demo

# Check ArgoCD status
kubectl get application -n argocd

# View application logs
kubectl logs -n nginx-app-dev deployment/nginx-app
kubectl logs -n nginx-app-staging deployment/nginx-app
kubectl logs -n nginx-app-prod deployment/nginx-app

# Check Helm chart
helm template helm-chart -f overlays/dev/values.yaml
```

## Cleanup

```bash
# Stop port forwarding
pm2 stop all
pm2 delete all

# Delete ArgoCD applications
kubectl delete -f argocd/

# Delete Kargo resources
kubectl delete -f kargo/

# Delete namespaces
kubectl delete namespace nginx-app-dev nginx-app-staging nginx-app-prod
```

## Next Steps

- Add production stage to Kargo
- Implement automated testing in the pipeline
- Add monitoring and alerting
- Configure webhook endpoints for external integrations
- Add security policies and RBAC 