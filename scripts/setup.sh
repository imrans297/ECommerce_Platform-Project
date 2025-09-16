#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="ecommerce-platform"
AWS_REGION="us-west-2"
ENVIRONMENT="${ENVIRONMENT:-dev}"

echo -e "${BLUE}🚀 Starting Enterprise DevOps Project Setup${NC}"
echo -e "${BLUE}Project: ${PROJECT_NAME}${NC}"
echo -e "${BLUE}Environment: ${ENVIRONMENT}${NC}"
echo -e "${BLUE}Region: ${AWS_REGION}${NC}"

# Function to print status
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    echo -e "${BLUE}📋 Checking prerequisites...${NC}"
    
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed. Please install it first."
        exit 1
    fi
    
    # Check if helm is installed
    if ! command -v helm &> /dev/null; then
        print_error "Helm is not installed. Please install it first."
        exit 1
    fi
    
    # Check if terraform is installed
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install it first."
        exit 1
    fi
    
    # Check if docker is installed
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install it first."
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured. Run 'aws configure' first."
        exit 1
    fi
    
    print_status "All prerequisites met"
}

# Setup Terraform backend
setup_terraform_backend() {
    echo -e "${BLUE}🏗️  Setting up Terraform backend...${NC}"
    
    # Create S3 bucket for Terraform state
    BUCKET_NAME="${PROJECT_NAME}-terraform-state-$(date +%s)"
    
    aws s3api create-bucket \
        --bucket ${BUCKET_NAME} \
        --region ${AWS_REGION} \
        --create-bucket-configuration LocationConstraint=${AWS_REGION} || true
    
    # Enable versioning
    aws s3api put-bucket-versioning \
        --bucket ${BUCKET_NAME} \
        --versioning-configuration Status=Enabled
    
    # Enable encryption
    aws s3api put-bucket-encryption \
        --bucket ${BUCKET_NAME} \
        --server-side-encryption-configuration '{
            "Rules": [
                {
                    "ApplyServerSideEncryptionByDefault": {
                        "SSEAlgorithm": "AES256"
                    }
                }
            ]
        }'
    
    # Create DynamoDB table for state locking
    aws dynamodb create-table \
        --table-name terraform-state-lock \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
        --region ${AWS_REGION} || true
    
    # Update Terraform backend configuration
    sed -i "s/ecommerce-terraform-state/${BUCKET_NAME}/g" infrastructure/terraform/main.tf
    
    print_status "Terraform backend configured"
}

# Initialize Terraform
init_terraform() {
    echo -e "${BLUE}🔧 Initializing Terraform...${NC}"
    
    cd infrastructure/terraform
    
    # Initialize Terraform
    terraform init
    
    # Create terraform.tfvars if it doesn't exist
    if [ ! -f terraform.tfvars ]; then
        cat > terraform.tfvars << EOF
aws_region = "${AWS_REGION}"
environment = "${ENVIRONMENT}"
project_name = "${PROJECT_NAME}"
owner = "$(whoami)"

# Database configuration
db_password = "$(openssl rand -base64 32)"
redis_auth_token = "$(openssl rand -base64 32)"

# Node configuration
node_instance_types = ["t3.medium"]
node_group_desired_size = 2
node_group_min_size = 1
node_group_max_size = 5

# RDS configuration
rds_instance_class = "db.t3.micro"
rds_allocated_storage = 20

# Redis configuration
redis_node_type = "cache.t3.micro"
EOF
    fi
    
    cd ../..
    
    print_status "Terraform initialized"
}

# Deploy infrastructure
deploy_infrastructure() {
    echo -e "${BLUE}🏗️  Deploying infrastructure...${NC}"
    
    cd infrastructure/terraform
    
    # Plan deployment
    terraform plan -out=tfplan
    
    # Apply deployment
    terraform apply tfplan
    
    # Save outputs
    terraform output -json > ../../outputs.json
    
    cd ../..
    
    print_status "Infrastructure deployed"
}

# Configure kubectl
configure_kubectl() {
    echo -e "${BLUE}⚙️  Configuring kubectl...${NC}"
    
    # Get cluster name from Terraform output
    CLUSTER_NAME=$(jq -r '.cluster_name.value' outputs.json)
    
    # Update kubeconfig
    aws eks update-kubeconfig --region ${AWS_REGION} --name ${CLUSTER_NAME}
    
    # Verify connection
    kubectl get nodes
    
    print_status "kubectl configured"
}

# Install monitoring stack
install_monitoring() {
    echo -e "${BLUE}📊 Installing monitoring stack...${NC}"
    
    # Add Helm repositories
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo add grafana https://grafana.github.io/helm-charts
    helm repo update
    
    # Create monitoring namespace
    kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
    
    # Install Prometheus and Grafana
    helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
        --namespace monitoring \
        --set grafana.adminPassword=admin123 \
        --set grafana.service.type=LoadBalancer \
        --wait
    
    print_status "Monitoring stack installed"
}

# Install logging stack
install_logging() {
    echo -e "${BLUE}📝 Installing logging stack...${NC}"
    
    # Add Elastic Helm repository
    helm repo add elastic https://helm.elastic.co
    helm repo update
    
    # Create logging namespace
    kubectl create namespace logging --dry-run=client -o yaml | kubectl apply -f -
    
    # Install Elasticsearch
    helm upgrade --install elasticsearch elastic/elasticsearch \
        --namespace logging \
        --set replicas=1 \
        --set minimumMasterNodes=1 \
        --set resources.requests.cpu=100m \
        --set resources.requests.memory=512Mi \
        --wait
    
    # Install Kibana
    helm upgrade --install kibana elastic/kibana \
        --namespace logging \
        --set service.type=LoadBalancer \
        --wait
    
    # Install Filebeat
    helm upgrade --install filebeat elastic/filebeat \
        --namespace logging \
        --wait
    
    print_status "Logging stack installed"
}

# Install service mesh
install_service_mesh() {
    echo -e "${BLUE}🕸️  Installing Istio service mesh...${NC}"
    
    # Download and install Istio
    curl -L https://istio.io/downloadIstio | sh -
    export PATH=$PWD/istio-*/bin:$PATH
    
    # Install Istio
    istioctl install --set values.defaultRevision=default -y
    
    # Enable sidecar injection for default namespace
    kubectl label namespace default istio-injection=enabled --overwrite
    
    # Install Istio addons
    kubectl apply -f istio-*/samples/addons/
    
    print_status "Service mesh installed"
}

# Setup CI/CD
setup_cicd() {
    echo -e "${BLUE}🔄 Setting up CI/CD...${NC}"
    
    # Install ArgoCD
    kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    
    # Wait for ArgoCD to be ready
    kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
    
    # Install Jenkins
    helm repo add jenkins https://charts.jenkins.io
    helm repo update
    
    kubectl create namespace jenkins --dry-run=client -o yaml | kubectl apply -f -
    
    helm upgrade --install jenkins jenkins/jenkins \
        --namespace jenkins \
        --set controller.serviceType=LoadBalancer \
        --set controller.adminPassword=admin123 \
        --wait
    
    print_status "CI/CD tools installed"
}

# Build and push Docker images
build_images() {
    echo -e "${BLUE}🐳 Building Docker images...${NC}"
    
    # Get ECR repository URI
    ECR_REGISTRY=$(jq -r '.ecr_registry.value' outputs.json)
    
    # Login to ECR
    aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
    
    # Build and push user service
    cd applications/user-service
    docker build -t user-service .
    docker tag user-service:latest ${ECR_REGISTRY}/user-service:latest
    docker push ${ECR_REGISTRY}/user-service:latest
    cd ../..
    
    print_status "Docker images built and pushed"
}

# Deploy applications
deploy_applications() {
    echo -e "${BLUE}🚀 Deploying applications...${NC}"
    
    # Apply Kubernetes manifests
    kubectl apply -f kubernetes/manifests/
    
    # Install application Helm chart
    helm upgrade --install ecommerce kubernetes/helm/ecommerce \
        --namespace default \
        --wait
    
    print_status "Applications deployed"
}

# Display access information
display_access_info() {
    echo -e "${BLUE}📋 Access Information${NC}"
    
    # Get LoadBalancer IPs
    echo -e "${GREEN}Grafana:${NC}"
    kubectl get svc prometheus-grafana -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' && echo ":3000"
    echo -e "Username: admin, Password: admin123"
    
    echo -e "${GREEN}Kibana:${NC}"
    kubectl get svc kibana-kibana -n logging -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' && echo ":5601"
    
    echo -e "${GREEN}ArgoCD:${NC}"
    kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' && echo ":443"
    echo -e "Username: admin"
    echo -e "Password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)"
    
    echo -e "${GREEN}Jenkins:${NC}"
    kubectl get svc jenkins -n jenkins -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' && echo ":8080"
    echo -e "Username: admin, Password: admin123"
}

# Main execution
main() {
    check_prerequisites
    setup_terraform_backend
    init_terraform
    deploy_infrastructure
    configure_kubectl
    install_monitoring
    install_logging
    install_service_mesh
    setup_cicd
    build_images
    deploy_applications
    display_access_info
    
    echo -e "${GREEN}🎉 Setup completed successfully!${NC}"
    echo -e "${YELLOW}📚 Check the documentation for next steps${NC}"
}

# Run main function
main "$@"