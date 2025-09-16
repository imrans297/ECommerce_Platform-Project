#!/bin/bash

echo "🚀 Setting up E-commerce Platform (AWS Free Tier)"

# Check prerequisites
command -v docker >/dev/null 2>&1 || { echo "Docker required but not installed. Aborting." >&2; exit 1; }
command -v terraform >/dev/null 2>&1 || { echo "Terraform required but not installed. Aborting." >&2; exit 1; }
command -v aws >/dev/null 2>&1 || { echo "AWS CLI required but not installed. Aborting." >&2; exit 1; }

# Set environment variables
export AWS_REGION=us-east-1
export ENVIRONMENT=dev

echo "📦 Starting local development environment..."

# Start local services with resource limits
docker-compose -f docker-compose.free.yml up -d

echo "⏳ Waiting for services to start..."
sleep 30

# Check service health
echo "🔍 Checking service health..."
curl -f http://localhost:3000/health || echo "User service not ready"
curl -f http://localhost:5000/health || echo "Product service not ready"
curl -f http://localhost:9000/health || echo "Notification service not ready"

echo "✅ Local development environment ready!"
echo "📊 Prometheus: http://localhost:9090"
echo "🛍️  User Service: http://localhost:3000"
echo "📦 Product Service: http://localhost:5000"
echo "📧 Notification Service: http://localhost:9000"

echo ""
echo "💰 AWS Free Tier Resources:"
echo "- RDS PostgreSQL: db.t3.micro (750 hours/month)"
echo "- ElastiCache Redis: cache.t3.micro"
echo "- S3: 5GB storage"
echo "- EC2: t3.micro instances"
echo ""
echo "🚀 To deploy to AWS (Fixed Steps):"
echo "cd infrastructure/terraform"
echo "terraform init -backend-config=backend-dev.hcl"
echo ""
echo "Set required variables:"
echo "export TF_VAR_db_password='YourSecurePassword123!'"
echo "export TF_VAR_redis_auth_token='YourRedisToken123!'"
echo "export TF_VAR_datadog_api_key='your-datadog-api-key'"
echo "export TF_VAR_datadog_app_key='your-datadog-app-key'"
echo ""
echo "Deploy in stages:"
echo "terraform apply -target='module.vpc' -var-file=environments/dev-free.tfvars -auto-approve"
echo "terraform apply -target='module.security' -target='module.iam' -var-file=environments/dev-free.tfvars -auto-approve"
echo "terraform apply -var-file=environments/dev-free.tfvars -auto-approve"