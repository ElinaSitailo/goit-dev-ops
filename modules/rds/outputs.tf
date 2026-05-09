
# -----------------------------------------------------------------------
#               Shared
# -----------------------------------------------------------------------

output "subnet_group_id" {
  description = "ID of the DB subnet group"
  value       = aws_db_subnet_group.main.id
}

output "security_group_id" {
  description = "ID of the RDS/Aurora security group"
  value       = aws_security_group.rds.id
}

# -----------------------------------------------------------------------
#               Standard RDS MySQL outputs
# -----------------------------------------------------------------------

output "db_instance_id" {
  description = "ID of the RDS DB instance (empty for Aurora)"
  value       = var.use_aurora ? null : aws_db_instance.mysql[0].id
}

output "db_instance_arn" {
  description = "ARN of the RDS DB instance (empty for Aurora)"
  value       = var.use_aurora ? null : aws_db_instance.mysql[0].arn
}

output "endpoint" {
  description = "Connection endpoint for the database (instance endpoint for RDS, cluster writer endpoint for Aurora)"
  value       = var.use_aurora ? aws_rds_cluster.aurora_mysql[0].endpoint : aws_db_instance.mysql[0].address
}

output "port" {
  description = "Port the database listens on"
  value       = var.use_aurora ? aws_rds_cluster.aurora_mysql[0].port : aws_db_instance.mysql[0].port
}

# -----------------------------------------------------------------------
#               Aurora MySQL outputs
# -----------------------------------------------------------------------

output "cluster_id" {
  description = "ID of the Aurora cluster (empty for standard RDS)"
  value       = var.use_aurora ? aws_rds_cluster.aurora_mysql[0].id : null
}

output "cluster_arn" {
  description = "ARN of the Aurora cluster (empty for standard RDS)"
  value       = var.use_aurora ? aws_rds_cluster.aurora_mysql[0].arn : null
}

output "reader_endpoint" {
  description = "Read-only endpoint for the Aurora cluster (empty for standard RDS)"
  value       = var.use_aurora ? aws_rds_cluster.aurora_mysql[0].reader_endpoint : null
}
