locals {
  # Environment-specific naming
  name_prefix  = "${var.project_name}-${var.environment}"
  cluster_name = "${local.name_prefix}-eks"
  
  # Common tags applied to all resources
  common_tags = {
    Environment   = var.environment
    Project       = var.project_name
    ManagedBy     = "Imran"
    Owner         = var.owner
    CostCenter    = var.cost_center
    CreatedDate   = formatdate("YYYY-MM-DD", timestamp())
  }
  
  # Availability zones
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
  
  # Environment-specific configurations
  is_production = var.environment == "prod"
  
  # Security configurations
  enable_deletion_protection = local.is_production
  backup_retention_days     = local.is_production ? 30 : 7
  
  # Monitoring configurations
  enable_detailed_monitoring = local.is_production
  log_retention_days        = local.is_production ? 90 : 30
}