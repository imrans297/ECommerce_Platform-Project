output "db_instance_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.postgres.endpoint
}

output "db_instance_name" {
  description = "RDS instance database name"
  value       = aws_db_instance.postgres.db_name
}

output "db_instance_username" {
  description = "RDS instance username"
  value       = aws_db_instance.postgres.username
  sensitive   = true
}

output "db_instance_port" {
  description = "RDS instance port"
  value       = aws_db_instance.postgres.port
}