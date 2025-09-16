variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs"
  type        = list(string)
}

variable "node_instance_types" {
  description = "Instance types for EKS nodes"
  type        = list(string)
}

variable "node_group_min_size" {
  description = "Minimum size of node group"
  type        = number
}

variable "node_group_max_size" {
  description = "Maximum size of node group"
  type        = number
}

variable "node_group_desired_size" {
  description = "Desired size of node group"
  type        = number
}

variable "key_pair_name" {
  description = "EC2 Key Pair name"
  type        = string
}

variable "node_security_group_id" {
  description = "Node security group ID"
  type        = string
}

variable "eks_kms_key_arn" {
  description = "EKS KMS key ARN"
  type        = string
}

variable "ebs_kms_key_arn" {
  description = "EBS KMS key ARN"
  type        = string
}

variable "eks_admin_role_arn" {
  description = "EKS admin role ARN"
  type        = string
}

variable "aws_auth_users" {
  description = "AWS auth users"
  type        = list(any)
  default     = []
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
}