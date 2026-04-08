# -----------------------------------------------------------------------
#                           Variables of s3-backend module
# -----------------------------------------------------------------------
#                           Main
# -----------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string
}

variable "project" {
  description = "Project name for tagging resources"
  type        = string
}

# -----------------------------------------------------------------------
#                           S3
# -----------------------------------------------------------------------

variable "bucket_name" {
  description = "Unique name for the S3 bucket to store Terraform state"
  type        = string

  validation {
    # Amazon S3 and Google Cloud Storage (GCS) bucket names must be between 3 and 63 characters long. 
    # Names must consist only of lowercase letters, numbers, hyphens (-), and periods (.).
    condition     = length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63
    error_message = "The bucket name must be between 3 and 63 characters."
  }
}

variable "enable_versioning" {
  description = "Enable versioning for the S3 bucket"
  type        = bool
}

variable "force_destroy" {
  description = "Allow deletion of the bucket with its contents"
  type        = bool
}

# -----------------------------------------------------------------------
#                           DynamoDB
# -----------------------------------------------------------------------
variable "table_name" {
  description = "DynamoDB table name for state locking"
  type        = string
}

variable "table_hash_key" {
  description = "Hash key for the DynamoDB table"
  type        = string
}



