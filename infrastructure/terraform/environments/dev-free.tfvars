# Environment Configuration - AWS Free Tier Optimized
aws_region = "us-east-1"
environment = "dev"
project_name = "ecommerce-platform"
owner = "devops-team"
cost_center = "engineering"

# Network Configuration
vpc_cidr = "10.0.0.0/16"
private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
public_subnets = ["10.0.101.0/24", "10.0.102.0/24"]
database_subnets = ["10.0.201.0/24", "10.0.202.0/24"]

# EKS Configuration - Upgraded to t3.medium
kubernetes_version = "1.28"
node_instance_types = ["t3.medium"]  # Upgraded to t3.medium for better performance
node_group_min_size = 1
node_group_max_size = 3
node_group_desired_size = 2
key_pair_name = "ecommerce-dev-key"
aws_auth_users = []

# Database Configuration - Free Tier
rds_instance_class = "db.t3.micro"  # 750 hours free
rds_allocated_storage = 20          # 20GB free
rds_max_allocated_storage = 20      # Don't auto-scale beyond free tier
db_name = "ecommerce_dev"
db_username = "postgres"
db_password = "SecurePassword123!"

# Redis Configuration - Free Tier
redis_node_type = "cache.t3.micro"  # Smallest available
redis_auth_token = "RedisToken123!"