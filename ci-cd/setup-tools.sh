#!/bin/bash

echo "🚀 Setting up DevOps Tools: SonarQube, Artifactory"

# Deploy SonarQube
echo "📊 Deploying SonarQube..."
kubectl apply -f ci-cd/sonarqube/sonarqube-deployment.yaml

# Deploy Artifactory
echo "📦 Deploying Artifactory..."
kubectl apply -f ci-cd/artifactory/artifactory-deployment.yaml

# Wait for deployments
echo "⏳ Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/sonarqube -n sonarqube
kubectl wait --for=condition=available --timeout=300s deployment/artifactory -n artifactory

# Get service URLs
echo "🔗 Getting service URLs..."
SONAR_URL=$(kubectl get svc sonarqube -n sonarqube -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
ARTIFACTORY_URL=$(kubectl get svc artifactory -n artifactory -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

echo "✅ DevOps Tools deployed successfully!"
echo ""
echo "🔗 Access URLs:"
echo "SonarQube: http://${SONAR_URL}:9000 (admin/admin)"
echo "Artifactory: http://${ARTIFACTORY_URL}:8082 (admin/password)"
echo ""
echo "📋 Next steps:"
echo "1. Configure SonarQube projects and quality gates"
echo "2. Set up Artifactory repositories"
echo "3. Update Jenkins credentials with actual tokens"
echo "4. Configure security scanning tools"