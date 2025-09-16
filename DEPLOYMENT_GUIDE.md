# E-commerce Platform Deployment Guide

## 🚀 Quick Start (Fixed Version)

### Prerequisites
- AWS CLI configured with appropriate permissions
- Terraform >= 1.0
- kubectl
- Docker & Docker Compose (for local development)

### 1. Local Development First
```bash
# Start local services with Docker Compose
docker-compose -f docker-compose.yml up -d

# Verify services
curl http://localhost:3000/health  # User Service
curl http://localhost:5000/health  # Product Service
curl http://localhost:8080/health  # Order Service
curl http://localhost:9000/health  # Notification Service
```

### 2. AWS Infrastructure Deployment

#### Step 1: Initialize Terraform
```bash
cd infrastructure/terraform
terraform init -backend-config=backend-dev.hcl
```

#### Step 2: Set Required Variables
```bash
export TF_VAR_db_password="YourSecurePassword123!"
export TF_VAR_redis_auth_token="YourRedisToken123!"
export TF_VAR_datadog_api_key="your-datadog-api-key"
export TF_VAR_datadog_app_key="your-datadog-app-key"
```

#### Step 3: Deploy Infrastructure (Fixed Order)
```bash
# Deploy VPC and networking first
terraform apply -target='module.vpc' -var-file="environments/dev.tfvars" -auto-approve

# Deploy security and IAM
terraform apply -target='module.security' -target='module.iam' -var-file="environments/dev.tfvars" -auto-approve

# Deploy databases
terraform apply -target='module.rds' -target='module.redis' -var-file="environments/dev.tfvars" -auto-approve

# Deploy EKS cluster (without node groups)
terraform apply -target='module.eks.module.eks.aws_eks_cluster' -var-file="environments/dev.tfvars" -auto-approve

# Finally deploy node groups
terraform apply -var-file="environments/dev.tfvars" -auto-approve
```

## 🔧 Issues Fixed

### 1. KMS Key Issues
**Problem**: EBS encryption with custom KMS keys caused node group failures
**Solution**: Simplified to use default EBS configuration initially

### 2. NAT Gateway Missing
**Problem**: Private subnets without NAT Gateway prevented nodes from joining cluster
**Solution**: Always create NAT Gateway, even for dev environment

### 3. Region Inconsistency
**Problem**: Resources created in different regions (us-east-1 vs us-west-2)
**Solution**: Standardized on us-east-1 for all resources

### 4. Node Group Complexity
**Problem**: Complex launch template configurations caused conflicts
**Solution**: Simplified node group configuration

### 5. S3 Bucket Region Conflicts
**Problem**: S3 bucket created in wrong region
**Solution**: Ensure all resources use same region

## 📋 Deployment Checklist

### Pre-deployment
- [ ] AWS credentials configured
- [ ] All required environment variables set
- [ ] Terraform backend S3 bucket exists
- [ ] DynamoDB table for state locking exists

### Deployment Steps
- [ ] VPC and networking deployed
- [ ] NAT Gateway created and routes configured
- [ ] Security groups and IAM roles created
- [ ] RDS and Redis deployed
- [ ] EKS cluster created
- [ ] Node groups joined successfully
- [ ] kubectl configured
- [ ] Applications deployed

### Post-deployment Verification
```bash
# Verify EKS cluster
aws eks describe-cluster --name ecommerce-platform-dev-eks --region us-east-1

# Verify nodes joined
kubectl get nodes

# Verify services
kubectl get pods -A

# Test application endpoints
kubectl get svc
```

## 🐳 Docker Images Built

The following services have Docker images ready:
- **User Service** (Node.js): `user-service:latest`
- **Product Service** (Python Flask): `product-service:latest`
- **Order Service** (Java Spring Boot): `order-service:latest`
- **Notification Service** (Go): `notification-service:latest`
- **Frontend** (React.js): `frontend:latest`

## 📊 DataDog Integration

DataDog monitoring is configured and ready:
- Agent deployment via Helm
- Custom dashboards for each service
- Alerts for critical metrics
- Log aggregation from all services

**Note**: Keep DataDog configuration as-is - it's properly configured.

## 🚨 Troubleshooting

### Node Groups Not Joining
1. Check NAT Gateway exists: `aws ec2 describe-nat-gateways --region us-east-1`
2. Verify route tables: `aws ec2 describe-route-tables --region us-east-1`
3. Check security groups allow required traffic

### EKS Cluster Issues
1. Verify IAM roles have correct policies
2. Check VPC configuration and subnets
3. Ensure cluster endpoint access is configured

### Terraform State Issues
1. Force unlock if needed: `terraform force-unlock <lock-id>`
2. Import resources if state is out of sync
3. Use targeted applies for specific resources

## 💰 Cost Optimization

### Free Tier Resources Used
- RDS: db.t3.micro (750 hours/month free)
- ElastiCache: cache.t3.micro
- EKS: Cluster free, pay for nodes
- EC2: t3.micro instances
- S3: 5GB free storage

### Cost Monitoring
- Set up billing alerts
- Use AWS Cost Explorer
- Monitor DataDog usage

## 🔄 CI/CD Pipeline

GitHub Actions workflows are configured for:
- Automated testing
- Docker image building
- Infrastructure deployment
- Application deployment to EKS

## 📝 Next Steps

1. Deploy applications to EKS cluster
2. Configure ingress controller
3. Set up SSL certificates
4. Configure monitoring dashboards
5. Set up backup strategies
6. Implement security scanning

## 🆘 Support

If you encounter issues:
1. Check this guide first
2. Review Terraform logs
3. Check AWS CloudTrail for API errors
4. Verify all prerequisites are met