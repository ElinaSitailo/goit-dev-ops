
# -----------------------------------------------------------------------
#               Shared: subnet group
# -----------------------------------------------------------------------

resource "aws_db_subnet_group" "main" {
  name        = "${var.name}-subnet-group"
  description = "Subnet group for ${var.name} RDS/Aurora"
  subnet_ids  = var.subnet_ids

  tags = {
    Name = "${var.name}-subnet-group"
  }
}

# -----------------------------------------------------------------------
#               Shared: security group
# -----------------------------------------------------------------------

resource "aws_security_group" "rds" {
  name        = "${var.name}-sg"
  description = "Allow inbound MySQL/Aurora traffic for ${var.name}"
  vpc_id      = var.vpc_id

  ingress {
    description     = "MySQL from allowed security groups"
    from_port       = var.port
    to_port         = var.port
    protocol        = "tcp"
    security_groups = var.allowed_security_group_ids
    cidr_blocks     = var.allowed_cidr_blocks
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-sg"
  }
}

# -----------------------------------------------------------------------
#               Shared: parameter groups
# -----------------------------------------------------------------------

# Extracts the major MySQL version (e.g. "8.0" from "8.0.32" or "8.0.mysql_aurora.3.07.1")
locals {
  mysql_major_version = regex("^(\\d+\\.\\d+)", var.engine_version)[0]
}

resource "aws_db_parameter_group" "mysql" {
  # Only created for standard RDS MySQL
  count = var.use_aurora ? 0 : 1

  name        = "${var.name}-mysql-params"
  family      = "mysql${local.mysql_major_version}"
  description = "Parameter group for ${var.name} MySQL ${local.mysql_major_version}"

  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  parameter {
    name  = "long_query_time"
    value = "2"
  }

  tags = {
    Name = "${var.name}-mysql-params"
  }
}

resource "aws_rds_cluster_parameter_group" "aurora_mysql" {
  # Only created for Aurora MySQL
  count = var.use_aurora ? 1 : 0

  name        = "${var.name}-aurora-mysql-params"
  family      = "aurora-mysql${local.mysql_major_version}"
  description = "Cluster parameter group for ${var.name} Aurora MySQL ${local.mysql_major_version}"

  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  parameter {
    name  = "long_query_time"
    value = "2"
  }

  tags = {
    Name = "${var.name}-aurora-mysql-params"
  }
}

# -----------------------------------------------------------------------
#               Standard RDS MySQL  (use_aurora = false)
# -----------------------------------------------------------------------

resource "aws_db_instance" "mysql" {
  count = var.use_aurora ? 0 : 1

  identifier = var.identifier

  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  db_name  = var.database_name
  username = var.database_username
  password = var.database_password
  port     = var.port

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  storage_encrypted     = var.storage_encrypted

  multi_az               = var.multi_az
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  parameter_group_name   = aws_db_parameter_group.mysql[0].name

  backup_retention_period = var.backup_retention_period
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window

  deletion_protection     = var.deletion_protection
  skip_final_snapshot     = var.skip_final_snapshot
  apply_immediately       = var.apply_immediately

  tags = {
    Name = var.name
  }
}

# -----------------------------------------------------------------------
#               Aurora MySQL cluster  (use_aurora = true)
# -----------------------------------------------------------------------

resource "aws_rds_cluster" "aurora_mysql" {
  count = var.use_aurora ? 1 : 0

  cluster_identifier = var.identifier

  engine         = var.engine
  engine_version = var.engine_version

  database_name   = var.database_name
  master_username = var.database_username
  master_password = var.database_password
  port            = var.port

  storage_encrypted = var.storage_encrypted

  db_subnet_group_name            = aws_db_subnet_group.main.name
  vpc_security_group_ids          = [aws_security_group.rds.id]
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.aurora_mysql[0].name

  backup_retention_period = var.backup_retention_period
  preferred_backup_window = var.backup_window
  preferred_maintenance_window = var.maintenance_window

  deletion_protection     = var.deletion_protection
  skip_final_snapshot     = var.skip_final_snapshot
  apply_immediately       = var.apply_immediately

  tags = {
    Name = var.name
  }
}

# Primary (writer) Aurora instance
resource "aws_rds_cluster_instance" "writer" {
  count = var.use_aurora ? 1 : 0

  identifier         = "${var.identifier}-writer"
  cluster_identifier = aws_rds_cluster.aurora_mysql[0].id

  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  db_subnet_group_name    = aws_db_subnet_group.main.name
  apply_immediately       = var.apply_immediately

  tags = {
    Name = "${var.name}-writer"
    Role = "writer"
  }
}

# Optional reader instance when multi_az = true
resource "aws_rds_cluster_instance" "reader" {
  count = var.use_aurora && var.multi_az ? 1 : 0

  identifier         = "${var.identifier}-reader"
  cluster_identifier = aws_rds_cluster.aurora_mysql[0].id

  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  db_subnet_group_name    = aws_db_subnet_group.main.name
  apply_immediately       = var.apply_immediately

  tags = {
    Name = "${var.name}-reader"
    Role = "reader"
  }
}
