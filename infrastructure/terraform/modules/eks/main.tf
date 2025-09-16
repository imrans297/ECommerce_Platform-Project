module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = var.cluster_name
  cluster_version = var.kubernetes_version

  vpc_id                         = var.vpc_id
  subnet_ids                     = var.subnet_ids
  cluster_endpoint_public_access = true
  cluster_endpoint_private_access = true

  # Disable problematic features
  cluster_encryption_config = {}
  create_cloudwatch_log_group = false

  # Disable addons that are causing timeouts
  cluster_addons = {}

  eks_managed_node_groups = {
    main = {
      name           = "main-node-group"
      instance_types = var.node_instance_types
      capacity_type  = "ON_DEMAND"
      
      min_size     = var.node_group_min_size
      max_size     = var.node_group_max_size
      desired_size = var.node_group_desired_size

      # Simplified configuration
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 20
            volume_type           = "gp3"
            encrypted             = false
            delete_on_termination = true
          }
        }
      }

      labels = {
        Environment = var.environment
        NodeGroup   = "main"
      }

      tags = var.common_tags
    }
  }

  manage_aws_auth_configmap = false
  tags = var.common_tags
}