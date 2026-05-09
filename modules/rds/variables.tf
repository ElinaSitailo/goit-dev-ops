
# -----------------------------------------------------------------------
#               Identity / Naming
# -----------------------------------------------------------------------

variable "identifier" {
  description = "Unique identifier for the RDS instance or Aurora cluster"
  type        = string
}

variable "name" {
  description = "Name tag applied to all RDS resources"
  type        = string
}

# -----------------------------------------------------------------------
#               Engine selection
# -----------------------------------------------------------------------

variable "use_aurora" {
  description = "When true, creates an Aurora MySQL cluster; when false, creates a standard RDS MySQL instance"
  type        = bool
  default     = false
}

variable "engine" {
  description = "Database engine (mysql for RDS, aurora-mysql for Aurora)"
  type        = string
  default     = "mysql"

  validation {
    condition     = contains(["mysql", "aurora-mysql"], var.engine)
    error_message = "engine must be 'mysql' or 'aurora-mysql'."
  }
}

variable "engine_version" {
  description = "Database engine version (e.g. '8.0' for MySQL, '8.0.mysql_aurora.3.07.1' for Aurora MySQL)"
  type        = string
  default     = "8.0"
}

variable "instance_class" {
  description = "Instance class for the DB instance or Aurora cluster instance (e.g. db.t3.micro, db.r6g.large)"
  type        = string
  default     = "db.t3.micro"
}

# -----------------------------------------------------------------------
#               Database settings
# -----------------------------------------------------------------------

variable "database_name" {
  description = "Name of the initial database to create"
  type        = string
  default     = "appdb"
}

variable "database_username" {
  description = "Master username for the database"
  type        = string
  default     = "admin"
}

variable "database_password" {
  description = "Master password for the database"
  type        = string
  sensitive   = true
}

variable "port" {
  description = "TCP port the database listens on"
  type        = number
  default     = 3306
}

# -----------------------------------------------------------------------
#               Storage (RDS only — Aurora manages storage automatically)
# -----------------------------------------------------------------------

variable "allocated_storage" {
  description = "Initial storage size in GiB (RDS only; ignored for Aurora)"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Upper limit for autoscaling storage in GiB; 0 disables autoscaling (RDS only)"
  type        = number
  default     = 100
}

variable "storage_type" {
  description = "Storage type for RDS: gp2, gp3, or io1 (ignored for Aurora)"
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp2", "gp3", "io1"], var.storage_type)
    error_message = "storage_type must be 'gp2', 'gp3', or 'io1'."
  }
}

variable "storage_encrypted" {
  description = "Enable encryption at rest"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------
#               High-availability / placement
# -----------------------------------------------------------------------

variable "multi_az" {
  description = "Deploy a standby replica in a second AZ (RDS); for Aurora this controls whether a reader instance is added"
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "ID of the VPC to deploy the database into"
  type        = string
}

variable "subnet_ids" {
  description = "List of private subnet IDs for the DB subnet group (minimum two AZs required by AWS)"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "You must provide at least two subnet IDs (in different AZs) for the DB subnet group."
  }
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks permitted to reach the database port (e.g. VPC CIDR)"
  type        = list(string)
  default     = []
}

variable "allowed_security_group_ids" {
  description = "IDs of security groups permitted to reach the database port (e.g. EKS node group SG)"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------
#               Backup / maintenance
# -----------------------------------------------------------------------

variable "backup_retention_period" {
  description = "Days to retain automated backups (0 disables backups)"
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_period >= 0 && var.backup_retention_period <= 35
    error_message = "backup_retention_period must be between 0 and 35."
  }
}

variable "backup_window" {
  description = "Preferred UTC window for automated backups (HH:MM-HH:MM)"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Preferred UTC window for maintenance (ddd:HH:MM-ddd:HH:MM)"
  type        = string
  default     = "sun:05:00-sun:06:00"
}

variable "deletion_protection" {
  description = "Prevent accidental deletion of the database"
  type        = bool
  default     = false # Set to true in production
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot when the resource is destroyed"
  type        = bool
  default     = true # Set to false in production to retain a snapshot before destroy
}

variable "apply_immediately" {
  description = "Apply changes immediately rather than during the next maintenance window"
  type        = bool
  default     = false
}
