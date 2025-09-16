variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "database_subnet_group" {
  description = "Database subnet group name"
  type        = string
}

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
}

variable "rds_allocated_storage" {
  description = "RDS allocated storage"
  type        = number
}

variable "rds_max_allocated_storage" {
  description = "RDS max allocated storage"
  type        = number
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_username" {
  description = "Database username"
  type        = string
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "rds_security_group_id" {
  description = "RDS security group ID"
  type        = string
}

variable "rds_kms_key_arn" {
  description = "RDS KMS key ARN"
  type        = string
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
}