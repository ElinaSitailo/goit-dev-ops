
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
  default     = false
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
