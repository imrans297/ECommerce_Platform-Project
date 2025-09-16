# Use RDS Free Tier
resource "aws_db_instance" "postgres" {
  identifier = "${var.project_name}-${var.environment}-postgres"

  engine         = "postgres"
  engine_version = "15.7"  # Valid PostgreSQL version
  instance_class = "db.t3.micro"  # Free tier: 750 hours/month

  allocated_storage     = 20  # Free tier: 20GB
  max_allocated_storage = 20
  storage_type         = "gp2"
  storage_encrypted    = false  # Encryption not free

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  port     = 5432

  vpc_security_group_ids = [var.rds_security_group_id]
  db_subnet_group_name   = var.database_subnet_group

  backup_retention_period = 0  # No backups to save cost
  skip_final_snapshot    = true
  deletion_protection    = false

  tags = var.common_tags
}