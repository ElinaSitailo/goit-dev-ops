# -----------------------------------------------------------------------
#               Main
# -----------------------------------------------------------------------
output "aws_region" {
  description = "AWS region used for all resources"
  value       = var.main_aws_region
}

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
# -----------------------------------------------------------------------
#               EKS
# -----------------------------------------------------------------------
output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "Endpoint of the EKS cluster"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = module.eks.cluster_arn
}

output "eks_node_group_name" {
  description = "Name of the EKS node group"
  value       = module.eks.node_group_name
}

output "eks_node_group_arn" {
  description = "ARN of the EKS node group"
  value       = module.eks.node_group_arn
}

output "eks_node_group_instance_types" {
  description = "Instance types used in the EKS node group"
  value       = module.eks.node_group_instance_types
}

# -----------------------------------------------------------------------
#               Jenkins
# -----------------------------------------------------------------------

output "jenkins_namespace" {
  description = "Kubernetes namespace for Jenkins"
  value       = module.jenkins.namespace
}

output "jenkins_release_name" {
  description = "Helm release name for Jenkins"
  value       = module.jenkins.release_name
}

output "jenkins_service_external_hostname" {
  description = "Jenkins external DNS hostname"
  value       = module.jenkins.service_external_hostname
}

output "jenkins_service_external_ip" {
  description = "Jenkins external IP"
  value       = module.jenkins.service_external_ip
}

# -----------------------------------------------------------------------
#               Argo CD
# -----------------------------------------------------------------------

output "argocd_namespace" {
  description = "Kubernetes namespace for Argo CD"
  value       = module.argo_cd.namespace
}

output "argocd_release_name" {
  description = "Helm release name for Argo CD"
  value       = module.argo_cd.release_name
}

output "argocd_application_name" {
  description = "Argo CD Application name"
  value       = module.argo_cd.application_name
}

output "argocd_server_external_hostname" {
  description = "Argo CD server external DNS hostname"
  value       = module.argo_cd.server_external_hostname
}

output "argocd_server_external_ip" {
  description = "Argo CD server external IP"
  value       = module.argo_cd.server_external_ip
}

# -----------------------------------------------------------------------
#               RDS
# -----------------------------------------------------------------------

output "rds_endpoint" {
  description = "Primary connection endpoint (writer endpoint for Aurora, instance address for RDS)"
  value       = module.rds.endpoint
}

output "rds_port" {
  description = "Database port"
  value       = module.rds.port
}

output "rds_reader_endpoint" {
  description = "Read-only endpoint for Aurora cluster (null for standard RDS)"
  value       = module.rds.reader_endpoint
}

output "rds_security_group_id" {
  description = "ID of the RDS/Aurora security group"
  value       = module.rds.security_group_id
}

output "rds_db_instance_id" {
  description = "RDS DB instance ID (null for Aurora)"
  value       = module.rds.db_instance_id
}

output "rds_cluster_id" {
  description = "Aurora cluster ID (null for standard RDS)"
  value       = module.rds.cluster_id
}
