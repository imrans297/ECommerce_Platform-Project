# Environment Configuration
aws_region = "us-west-2"
environment = "prod"
project_name = "ecommerce-platform"
owner = "devops-team"

# Network Configuration
vpc_cidr = "10.1.0.0/16"
private_subnets = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
public_subnets = ["10.1.101.0/24", "10.1.102.0/24", "10.1.103.0/24"]
database_subnets = ["10.1.201.0/24", "10.1.202.0/24", "10.1.203.0/24"]

# EKS Configuration
kubernetes_version = "1.28"
node_instance_types = ["m5.large", "m5.xlarge"]
node_group_min_size = 3
node_group_max_size = 10
node_group_desired_size = 5
key_pair_name = "ecommerce-prod-key"

# Database Configuration
rds_instance_class = "db.r5.large"
rds_allocated_storage = 100
rds_max_allocated_storage = 1000
db_name = "ecommerce_prod"
db_username = "postgres"

# Redis Configuration
redis_node_type = "cache.r5.large"