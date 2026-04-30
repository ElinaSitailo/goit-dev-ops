
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
  default     = "MUTABLE"
}

variable "ecr_force_delete" {
  description = "Force delete the ECR repository even if it contains images"
  type        = bool
  default     = true
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
  default     = true
}
# -----------------------------------------------------------------------
#               App secrets (set via TF_VAR_ in .env, never hardcoded)
# -----------------------------------------------------------------------

variable "database_password" {
  description = "Django app database password"
  type        = string
  sensitive   = true
}

variable "django_allowed_hosts" {
  description = "Django ALLOWED_HOSTS value (e.g. myapp.example.com)"
  type        = string
}
