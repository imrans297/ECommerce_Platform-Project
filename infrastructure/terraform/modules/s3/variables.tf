variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "s3_kms_key_arn" {
  description = "S3 KMS key ARN"
  type        = string
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
}