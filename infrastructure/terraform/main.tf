# VPC Module
module "vpc" {
  source = "./modules/vpc"
  
  project_name     = var.project_name
  environment      = var.environment
  vpc_cidr         = var.vpc_cidr
  private_subnets  = var.private_subnets
  public_subnets   = var.public_subnets
  database_subnets = var.database_subnets
  azs              = local.azs
  common_tags      = local.common_tags
}

# Security Module
module "security" {
  source = "./modules/security"
  
  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  vpc_cidr     = var.vpc_cidr
  common_tags  = local.common_tags
}

# IAM Module
module "iam" {
  source = "./modules/iam"
  
  project_name = var.project_name
  environment  = var.environment
  common_tags  = local.common_tags
}

# EKS Module
module "eks" {
  source = "./modules/eks"
  
  project_name              = var.project_name
  environment               = var.environment
  cluster_name              = local.cluster_name
  kubernetes_version        = var.kubernetes_version
  vpc_id                    = module.vpc.vpc_id
  subnet_ids                = module.vpc.private_subnets
  node_instance_types       = var.node_instance_types
  node_group_min_size       = var.node_group_min_size
  node_group_max_size       = var.node_group_max_size
  node_group_desired_size   = var.node_group_desired_size
  key_pair_name             = var.key_pair_name
  node_security_group_id    = module.security.node_security_group_id
  eks_kms_key_arn           = module.security.eks_kms_key_arn
  ebs_kms_key_arn           = module.security.ebs_kms_key_arn
  eks_admin_role_arn        = module.iam.eks_admin_role_arn
  aws_auth_users            = var.aws_auth_users
  common_tags               = local.common_tags
}

# RDS Module
module "rds" {
  source = "./modules/rds"
  
  project_name              = var.project_name
  environment               = var.environment
  vpc_id                    = module.vpc.vpc_id
  database_subnet_group     = module.vpc.database_subnet_group
  rds_instance_class        = var.rds_instance_class
  rds_allocated_storage     = var.rds_allocated_storage
  rds_max_allocated_storage = var.rds_max_allocated_storage
  db_name                   = var.db_name
  db_username               = var.db_username
  db_password               = var.db_password
  rds_security_group_id     = module.security.rds_security_group_id
  rds_kms_key_arn           = module.security.rds_kms_key_arn
  common_tags               = local.common_tags
}

# Redis Module
module "redis" {
  source = "./modules/redis"
  
  project_name            = var.project_name
  environment             = var.environment
  vpc_id                  = module.vpc.vpc_id
  private_subnets         = module.vpc.private_subnets
  redis_node_type         = var.redis_node_type
  redis_auth_token        = var.redis_auth_token
  redis_security_group_id = module.security.redis_security_group_id
  common_tags             = local.common_tags
}

# S3 Module
module "s3" {
  source = "./modules/s3"
  
  project_name   = var.project_name
  environment    = var.environment
  s3_kms_key_arn = module.security.s3_kms_key_arn
  common_tags    = local.common_tags
}

# DataDog AWS Integration Module
module "datadog_aws" {
  source = "./modules/datadog-aws"
  
  aws_account_id = data.aws_caller_identity.current.account_id
  environment    = var.environment
  
  providers = {
    datadog = datadog
  }
}

# DataDog Dashboards and Monitors Module
module "datadog" {
  source = "./modules/datadog"
  
  environment      = var.environment
  api_endpoint     = "https://${module.eks.cluster_endpoint}"
  datadog_api_key  = var.datadog_api_key
  datadog_app_key  = var.datadog_app_key
  
  providers = {
    datadog = datadog
  }
}