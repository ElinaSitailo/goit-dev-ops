
# -----------------------------------------------------------------------
#               Main
# -----------------------------------------------------------------------

variable "main_aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "eu-north-1"
}

variable "main_environment" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string
  default     = "lesson-5-dev-environment"
}

variable "main_project" {
  description = "Project name for tagging resources"
  type        = string
  default     = "lesson-5-project"
}

# -----------------------------------------------------------------------
#               S3
# -----------------------------------------------------------------------

variable "s3_bucket_name" {
  description = "S3 bucket name for Terraform state storage"
  type        = string
  default     = "ns-bucket-to-store-tf-state-devops-lesson-5-04082026"
}

# -----------------------------------------------------------------------
#               DynamoDB
# -----------------------------------------------------------------------

variable "dynamodb_table_name" {
  description = "DynamoDB table name for Terraform state locking"
  type        = string
  default     = "terraform-state-locks-table"
}

# -----------------------------------------------------------------------
#               VPC
# -----------------------------------------------------------------------

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = "lesson-5-vpc"
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_public_subnets" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "vpc_private_subnets" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

variable "vpc_availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["eu-north-1a", "eu-north-1b", "eu-north-1c"]
}

# -----------------------------------------------------------------------
#               ECR 
# -----------------------------------------------------------------------

variable "ecr_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "lesson-5-ecr"
}

variable "ecr_scan_on_push" {
  description = "Enable image scanning on push"
  type        = bool
  default     = true
}

variable "ecr_image_tag_mutability" {
  description = "Image tag mutability (MUTABLE or IMMUTABLE)"
  type        = string
  default     = "MUTABLE" # Use MUTABLE for development environments to allow tag updates, but consider IMMUTABLE for production to prevent accidental overwrites
}

variable "ecr_force_delete" {
  description = "Force delete the ECR repository even if it contains images"
  type        = bool
  default     = true # Set to true for development environments to allow easy cleanup, but be cautious in production environments
}

variable "ecr_max_image_count" {
  description = "Maximum number of images to retain in the repository"
  type        = number
  default     = 10
}

variable "ecr_encryption_type" {
  description = "Encryption type for the ECR repository (AES256 or KMS)"
  type        = string
  default     = "AES256"
}
# -----------------------------------------------------------------------
#               EKS 
# -----------------------------------------------------------------------
variable "eks_cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "lesson-7-eks"
}

variable "eks_cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.32" # fixed to 1.32 to prevent issues with older versions that is supported in the region and 'terraform apply' fails with "Error: creating EKS Node Group...Requested AMI for this version 1.29 is not supported" error
}

variable "eks_node_group_name" {
  description = "EKS node group name"
  type        = string
  default     = "lesson-7-nodes"
}

variable "eks_node_instance_types" {
  description = "EC2 instance types for EKS nodes"
  type        = list(string)
  default     = ["t3.medium"] # Use a smaller instance type for cost efficiency in development environments
}

variable "eks_node_desired_size" {
  description = "Desired number of EKS nodes"
  type        = number
  default     = 2
}

variable "eks_node_min_size" {
  description = "Minimum number of EKS nodes"
  type        = number
  default     = 1
}

variable "eks_node_max_size" {
  description = "Maximum number of EKS nodes"
  type        = number
  default     = 4
}

variable "eks_node_disk_size" {
  description = "Disk size (in GB) for EKS nodes"
  type        = number
  default     = 20
}

variable "eks_endpoint_private_access" {
  description = "Enable private access to the EKS endpoint"
  type        = bool
  default     = true
}

variable "eks_endpoint_public_access" {
  description = "Enable public access to the EKS endpoint"
  type        = bool
  default     = true # Enable public access for development environments to allow kubectl access from outside the VPC, but consider disabling in production for enhanced security
}
# -----------------------------------------------------------------------
#               App secrets (set via TF_VAR_ in .env, never hardcoded)
# -----------------------------------------------------------------------

variable "database_password" {
  description = "Django app database password"
  type        = string
  sensitive   = true
}

variable "django_secret_key" {
  description = "Django SECRET_KEY value"
  type        = string
  sensitive   = true
}

variable "django_allowed_hosts" {
  description = "Django ALLOWED_HOSTS value (e.g. myapp.example.com)"
  type        = string
}

# -----------------------------------------------------------------------
#               Jenkins (Helm + Terraform)
# -----------------------------------------------------------------------

variable "jenkins_namespace" {
  description = "Kubernetes namespace for Jenkins"
  type        = string
  default     = "jenkins"
}

variable "jenkins_release_name" {
  description = "Helm release name for Jenkins"
  type        = string
  default     = "jenkins"
}

variable "jenkins_admin_username" {
  description = "Jenkins admin username"
  type        = string
  default     = "admin"
}

variable "jenkins_admin_password" {
  description = "Jenkins admin password"
  type        = string
  sensitive   = true
}

variable "aws_access_key_id" {
  description = "AWS access key ID — used by the AWS CLI and provisioned as the aws-jenkins credential in Jenkins"
  type        = string
  sensitive   = true
}

variable "aws_secret_access_key" {
  description = "AWS secret access key — used by the AWS CLI and provisioned as the aws-jenkins credential in Jenkins"
  type        = string
  sensitive   = true
}

variable "jenkins_gitops_username" {
  description = "GitHub username provisioned as the gitops-repo-token credential in Jenkins"
  type        = string
}

variable "jenkins_gitops_token" {
  description = "GitHub PAT provisioned as the gitops-repo-token credential in Jenkins"
  type        = string
  sensitive   = true
}

# -----------------------------------------------------------------------
#               Argo CD (Helm + Terraform)
# -----------------------------------------------------------------------

variable "argocd_namespace" {
  description = "Kubernetes namespace for Argo CD"
  type        = string
  default     = "argocd"
}

variable "argocd_release_name" {
  description = "Helm release name for Argo CD"
  type        = string
  default     = "argocd"
}

variable "argocd_application_name" {
  description = "Argo CD Application resource name"
  type        = string
  default     = "django-app"
}

variable "argocd_application_repo_url" {
  description = "Git repository URL monitored by Argo CD"
  type        = string
  default     = "https://github.com/ElinaSitailo/goit-dev-ops.git"
}

variable "argocd_application_target_revision" {
  description = "Git revision/branch monitored by Argo CD"
  type        = string
  default     = "main"
}

variable "argocd_application_path" {
  description = "Path to Helm chart in the Git repository"
  type        = string
  default     = "charts/django-app"
}

variable "argocd_application_destination_namespace" {
  description = "Target namespace where Argo CD deploys the Helm chart"
  type        = string
  default     = "default"
}

variable "argocd_server_service_name" {
  description = "Argo CD server Service name used for endpoint output lookup"
  type        = string
  default     = "argocd-server"
}

# -----------------------------------------------------------------------
#               RDS
# -----------------------------------------------------------------------

variable "rds_use_aurora" {
  description = "When true, deploys Aurora MySQL; when false, deploys standard RDS MySQL"
  type        = bool
  default     = false
}

variable "rds_identifier" {
  description = "Unique identifier for the RDS instance or Aurora cluster"
  type        = string
  default     = "lesson-10-db"
}

variable "rds_name" {
  description = "Name tag applied to RDS resources"
  type        = string
  default     = "lesson-10-rds"
}

variable "rds_engine" {
  description = "Database engine: 'mysql' for standard RDS, 'aurora-mysql' for Aurora"
  type        = string
  default     = "mysql"
}

variable "rds_engine_version" {
  description = "Database engine version (e.g. '8.0' for MySQL, '8.0.mysql_aurora.3.07.1' for Aurora MySQL)"
  type        = string
  default     = "8.0"
}

variable "rds_instance_class" {
  description = "DB instance class (e.g. db.t3.micro, db.r6g.large)"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_multi_az" {
  description = "Enable Multi-AZ standby for RDS or add a reader instance for Aurora"
  type        = bool
  default     = false
}

variable "rds_database_name" {
  description = "Name of the initial database to create"
  type        = string
  default     = "appdb"
}

variable "rds_database_username" {
  description = "Master username for the database"
  type        = string
  default     = "admin"
}

variable "rds_allocated_storage" {
  description = "Initial storage size in GiB (RDS only)"
  type        = number
  default     = 20
}

variable "rds_max_allocated_storage" {
  description = "Upper limit for autoscaling storage in GiB (RDS only; 0 disables autoscaling)"
  type        = number
  default     = 100
}

variable "rds_storage_type" {
  description = "Storage type: gp2, gp3, or io1 (RDS only)"
  type        = string
  default     = "gp3"
}

variable "rds_backup_retention_period" {
  description = "Days to retain automated backups (0 disables backups)"
  type        = number
  default     = 7
}

variable "rds_deletion_protection" {
  description = "Prevent accidental deletion of the database"
  type        = bool
  default     = false
}

variable "rds_skip_final_snapshot" {
  description = "Skip final snapshot on destroy (set false in production)"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------
#               Monitoring (Prometheus + Grafana)
# -----------------------------------------------------------------------

variable "monitoring_namespace" {
  description = "Kubernetes namespace for Prometheus and Grafana"
  type        = string
  default     = "monitoring"
}

variable "monitoring_prometheus_release_name" {
  description = "Helm release name for kube-prometheus-stack"
  type        = string
  default     = "prometheus"
}

variable "monitoring_grafana_release_name" {
  description = "Helm release name for Grafana"
  type        = string
  default     = "grafana"
}

variable "monitoring_grafana_admin_user" {
  description = "Grafana admin username"
  type        = string
  default     = "admin"
}

variable "monitoring_grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
}

variable "monitoring_prometheus_storage_size" {
  description = "PersistentVolumeClaim size for Prometheus TSDB"
  type        = string
  default     = "10Gi"
}

variable "monitoring_grafana_storage_size" {
  description = "PersistentVolumeClaim size for Grafana"
  type        = string
  default     = "5Gi"
}
