#!/bin/bash

echo "🗑️  Deleting E-commerce Applications from EKS"

# Check if kubectl is configured
kubectl cluster-info > /dev/null 2>&1 || { echo "kubectl not configured. Exiting."; exit 1; }

# Delete all deployments in ecommerce namespace
echo "🔄 Deleting application deployments..."
kubectl delete deployment --all -n ecommerce

# Delete all services in ecommerce namespace
echo "🔄 Deleting application services..."
kubectl delete service --all -n ecommerce

# Delete all pods (if any are stuck)
echo "🔄 Deleting any remaining pods..."
kubectl delete pods --all -n ecommerce --force --grace-period=0

# Delete the entire namespace (this will clean up everything)
echo "🔄 Deleting ecommerce namespace..."
kubectl delete namespace ecommerce

echo "⏳ Waiting for namespace deletion to complete..."
kubectl wait --for=delete namespace/ecommerce --timeout=60s

echo "✅ All applications deleted successfully!"
echo ""
echo "🔍 Verify cleanup:"
echo "kubectl get namespaces"
echo "kubectl get pods --all-namespaces | grep ecommerce"