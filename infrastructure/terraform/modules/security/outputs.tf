output "eks_kms_key_arn" {
  description = "ARN of EKS KMS key"
  value       = aws_kms_key.eks.arn
}

output "ebs_kms_key_arn" {
  description = "ARN of EBS KMS key"
  value       = aws_kms_key.ebs.arn
}

output "rds_kms_key_arn" {
  description = "ARN of RDS KMS key"
  value       = aws_kms_key.rds.arn
}

output "s3_kms_key_arn" {
  description = "ARN of S3 KMS key"
  value       = aws_kms_key.s3.arn
}

output "node_security_group_id" {
  description = "ID of node security group"
  value       = aws_security_group.node_group_remote_access.id
}

output "rds_security_group_id" {
  description = "ID of RDS security group"
  value       = aws_security_group.rds.id
}

output "redis_security_group_id" {
  description = "ID of Redis security group"
  value       = aws_security_group.redis.id
}