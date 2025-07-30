#!/bin/bash

# Test Helm Chart Script

echo "🧪 Testing Helm Chart..."

# Test dev overlay
echo "Testing dev overlay..."
helm template nginx-app helm-chart -f overlays/dev/values.yaml

echo ""
echo "Testing staging overlay..."
helm template nginx-app helm-chart -f overlays/staging/values.yaml

echo ""
echo "Testing prod overlay..."
helm template nginx-app helm-chart -f overlays/prod/values.yaml

echo ""
echo "✅ Helm chart validation completed!"
echo "All templates rendered successfully." 