# -----------------------------------------------------------------------
#               S3
# -----------------------------------------------------------------------
output "bucket_name" {
  description = "S3 bucket name for Terraform state storage"
  value       = module.s3_backend.bucket_name
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = module.s3_backend.bucket_arn
}

# -----------------------------------------------------------------------
#               DynamoDB
# -----------------------------------------------------------------------

output "dynamodb_table_name" {
  description = "DynamoDB table name for state locking"
  value       = module.s3_backend.dynamodb_table_name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table"
  value       = module.s3_backend.dynamodb_table_arn
}

# -----------------------------------------------------------------------
#               VPC
# -----------------------------------------------------------------------
output "vpc_name" {
  description = "Name of the created VPC"
  value       = module.vpc.name
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = module.vpc.cidr
}

output "vpc_public_subnet_ids" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnet_ids
}

output "vpc_private_subnet_ids" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnet_ids
}

output "vpc_internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = module.vpc.internet_gateway_id
}

output "vpc_nat_gateway_ids" {
  description = "List of IDs of NAT Gateways"
  value       = module.vpc.nat_gateway_ids
}

# -----------------------------------------------------------------------
#               ECR 
# -----------------------------------------------------------------------

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = module.ecr.repository_url
}

output "ecr_repository_arn" {
  description = "ARN of the ECR repository"
  value       = module.ecr.repository_arn
}

output "ecr_registry_id" {
  description = "ID of the ECR registry"
  value       = module.ecr.registry_id
}
