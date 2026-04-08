# -----------------------------------------------------------------------
#                           S3
# -----------------------------------------------------------------------

output "bucket_name" {
  description = "Name of the S3 bucket for Terraform state storage"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "bucket_id" {
  description = "ID of the S3 bucket for Terraform state storage"
  value       = aws_s3_bucket.terraform_state.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket for Terraform state storage"
  value       = aws_s3_bucket.terraform_state.arn
}

output "bucket_domain_name" {
  description = "Domain name of the S3 bucket for Terraform state storage"
  value       = aws_s3_bucket.terraform_state.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "Regional domain name of the S3 bucket for Terraform state storage"
  value       = aws_s3_bucket.terraform_state.bucket_regional_domain_name
}

# -----------------------------------------------------------------------
#                           DynamoDB
# -----------------------------------------------------------------------

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table for Terraform state locking"
  value       = aws_dynamodb_table.terraform_locks.name
}

output "dynamodb_table_id" {
  description = "ID of the DynamoDB table for Terraform state locking"
  value       = aws_dynamodb_table.terraform_locks.id
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table for Terraform state locking"
  value       = aws_dynamodb_table.terraform_locks.arn
}

output "dynamodb_table_hash_key" {
  description = "Hash key of the DynamoDB table for Terraform state locking"
  value       = aws_dynamodb_table.terraform_locks.hash_key
}

