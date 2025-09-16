#!/bin/bash

echo "📊 Deploying DataDog to EKS Cluster"

# Check if kubectl is configured
kubectl cluster-info > /dev/null 2>&1 || { echo "kubectl not configured. Run: aws eks update-kubeconfig --region us-east-1 --name ecommerce-platform-dev-eks"; exit 1; }

# Check if DataDog API key is set
if [[ -z "$DATADOG_API_KEY" ]]; then
    echo "❌ DATADOG_API_KEY environment variable not set!"
    echo "Please set: export DATADOG_API_KEY='your-datadog-api-key'"
    exit 1
fi

# Add DataDog Helm repository
echo "📦 Adding DataDog Helm repository..."
helm repo add datadog https://helm.datadoghq.com
helm repo update

# Create DataDog namespace
echo "🏗️  Creating DataDog namespace..."
kubectl create namespace datadog --dry-run=client -o yaml | kubectl apply -f -

# Deploy DataDog Agent
echo "🚀 Deploying DataDog Agent..."
helm upgrade --install datadog-agent datadog/datadog \
  --namespace datadog \
  --set datadog.apiKey=$DATADOG_API_KEY \
  --set datadog.site="datadoghq.com" \
  --set datadog.logs.enabled=true \
  --set datadog.logs.containerCollectAll=true \
  --set datadog.apm.enabled=true \
  --set datadog.processAgent.enabled=true \
  --set networkMonitoring.enabled=true \
  --set systemProbe.enableTCPQueueLength=true \
  --set systemProbe.enableOOMKill=true \
  --set clusterAgent.enabled=true \
  --set clusterAgent.metricsProvider.enabled=true \
  --set datadog.clusterName="ecommerce-platform-dev-eks" \
  --set datadog.tags[0]="env:dev" \
  --set datadog.tags[1]="project:ecommerce-platform"

echo "⏳ Waiting for DataDog Agent to be ready..."
kubectl wait --for=condition=ready pod -l app=datadog-agent -n datadog --timeout=300s

echo "✅ DataDog Agent deployed successfully!"
echo ""
echo "🔍 Verify deployment:"
echo "kubectl get pods -n datadog"
echo "kubectl logs -l app=datadog-agent -n datadog"
echo ""
echo "📊 DataDog Dashboard: https://app.datadoghq.com/infrastructure"