#!/bin/bash

echo "🔧 E-commerce Platform - Fixed Deployment Script"
echo "This script applies all the lessons learned from previous deployment issues"

# Check prerequisites
command -v terraform >/dev/null 2>&1 || { echo "Terraform required but not installed. Aborting." >&2; exit 1; }
command -v aws >/dev/null 2>&1 || { echo "AWS CLI required but not installed. Aborting." >&2; exit 1; }

# Set region consistently
export AWS_DEFAULT_REGION=us-east-1
export AWS_REGION=us-east-1

echo "📍 Using region: us-east-1 (consistent across all resources)"

# Check if required environment variables are set
if [[ -z "$TF_VAR_db_password" || -z "$TF_VAR_redis_auth_token" || -z "$TF_VAR_datadog_api_key" || -z "$TF_VAR_datadog_app_key" ]]; then
    echo "❌ Required environment variables not set!"
    echo "Please set the following:"
    echo "export TF_VAR_db_password='YourSecurePassword123!'"
    echo "export TF_VAR_redis_auth_token='YourRedisToken123!'"
    echo "export TF_VAR_datadog_api_key='your-datadog-api-key'"
    echo "export TF_VAR_datadog_app_key='your-datadog-app-key'"
    exit 1
fi

cd infrastructure/terraform

echo "🏗️  Step 1: Initialize Terraform"
terraform init -backend-config=backend-dev.hcl

echo "🌐 Step 2: Deploy VPC and Networking (with NAT Gateway)"
terraform apply -target='module.vpc' -var-file="environments/dev.tfvars" -auto-approve

echo "🔒 Step 3: Deploy Security and IAM"
terraform apply -target='module.security' -target='module.iam' -var-file="environments/dev.tfvars" -auto-approve

echo "🗄️  Step 4: Deploy Databases"
terraform apply -target='module.rds' -target='module.redis' -var-file="environments/dev.tfvars" -auto-approve

echo "☸️  Step 5: Deploy EKS Cluster"
terraform apply -target='module.eks.module.eks.aws_eks_cluster' -var-file="environments/dev.tfvars" -auto-approve

echo "🖥️  Step 6: Deploy Node Groups (Simplified Configuration)"
terraform apply -var-file="environments/dev.tfvars" -auto-approve

echo "✅ Deployment Complete!"
echo ""
echo "🔍 Verification Steps:"
echo "aws eks describe-cluster --name ecommerce-platform-dev-eks --region us-east-1"
echo "aws eks update-kubeconfig --region us-east-1 --name ecommerce-platform-dev-eks"
echo "kubectl get nodes"
echo ""
echo "📊 Access Points:"
echo "- EKS Cluster: ecommerce-platform-dev-eks"
echo "- RDS Endpoint: Check Terraform outputs"
echo "- Redis Endpoint: Check Terraform outputs"
echo ""
echo "🐳 Next: Deploy Docker images to EKS cluster"
echo "📈 DataDog: Already configured and ready"