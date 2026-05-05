output "cluster_endpoint" {
  description = "EKS API endpoint for connecting to the cluster"
  value       = aws_eks_cluster.eks.endpoint
}

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.eks.name
}

output "cluster_version" {
  description = "Kubernetes version of the EKS cluster"
  value       = aws_eks_cluster.eks.version
}

output "cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = aws_eks_cluster.eks.arn
}

output "cluster_role_arn" {
  description = "IAM role ARN for EKS Cluster Control Plane"
  value       = aws_iam_role.eks_cluster_role.arn
}

output "node_group_role_arn" {
  description = "IAM role ARN for EKS Worker Nodes"
  value       = aws_iam_role.eks_node_group_role.arn
}

output "node_group_arn" {
  description = "ARN of the EKS node group"
  value       = aws_eks_node_group.general.arn
}

output "node_group_name" {
  description = "Name of the EKS node group"
  value       = aws_eks_node_group.general.node_group_name
}

output "node_group_instance_types" {
  description = "Instance types used in the EKS node group"
  value       = aws_eks_node_group.general.instance_types
}

output "cluster_security_group_id" {
  description = "Security group ID for the EKS cluster control plane"
  value       = aws_security_group.eks_cluster.id
}

output "cluster_vpc_id" {
  description = "VPC ID where the EKS cluster is deployed"
  value       = var.vpc_id
}

output "cluster_public_subnet_ids" {
  description = "List of public subnet IDs used by the EKS cluster"
  value       = var.public_subnet_ids
}

output "cluster_private_subnet_ids" {
  description = "List of private subnet IDs used by the EKS cluster"
  value       = var.private_subnet_ids
}

output "cluster_ca_certificate" {
  description = "Base64-encoded certificate authority data for the EKS cluster"
  value       = aws_eks_cluster.eks.certificate_authority[0].data
}

output "kubeconfig_command" {
  description = "Command to generate kubeconfig for connecting to the EKS cluster using AWS CLI"
  value       = "aws eks update-kubeconfig --name ${aws_eks_cluster.eks.name}"
}

