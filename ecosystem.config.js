module.exports = {
  apps: [
    {
      name: 'argocd-port-forward',
      script: 'kubectl',
      args: 'port-forward -n argocd svc/argocd-server 5003:443',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '1G',
      env: {
        NODE_ENV: 'development'
      }
    },
    {
      name: 'kargo-port-forward',
      script: 'kubectl',
      args: 'port-forward -n kargo svc/kargo-api 5004:80',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '1G',
      env: {
        NODE_ENV: 'development'
      }
    }
  ]
}; 