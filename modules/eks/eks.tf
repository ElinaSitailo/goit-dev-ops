# --------------------------------------------------------------------------------------------------
#   This module creates an Amazon  EKS (Elastic Kubernetes Service) cluster 
#   with associated resources such as node groups and IAM roles.
# --------------------------------------------------------------------------------------------------

# IAM-role for the EKS cluster control plane
resource "aws_iam_role" "eks_cluster_role" {
  # Name of the IAM role for the EKS cluster
  name = "${var.cluster_name}-eks-cluster"

  # Policy that allows the EKS service to assume this IAM role
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "sts:AssumeRole", # Allows the EKS service to assume this role
        Principal = {
          Service = "eks.amazonaws.com" # Allowed for the EKS service
        }
      }
    ]
  })
  tags = {
    Name = "${var.cluster_name}-cluster-role"
  }
}

# Attach IAM role to AmazonEKSClusterPolicy
resource "aws_iam_role_policy_attachment" "eks_cluster_policy_attachment" {

  # This is the primary required policy. 
  # It grants the EKS control plane permissions to manage resources 
  # such as Elastic Network Interfaces (ENIs) and security groups 
  # required for communication between the control plane and nodes.
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy" # ARN of the policy that grants permissions for the EKS cluster
  role       = aws_iam_role.eks_cluster_role.name               # IAM role to which the policy is attached
}

resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  # While often considered optional in older documentation, 
  # it is now standard for EKS clusters to allow the VPC Resource Controller 
  # to manage network resources for pods. 
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster_role.name
}

# Create a security group for the EKS cluster control plane
resource "aws_security_group" "eks_cluster" {
  name        = "${var.cluster_name}-cluster-sg"
  description = "Security group for EKS cluster control plane"
  vpc_id      = var.vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic from EKS cluster control plane to worker nodes and other resources"
  }

  tags = {
    Name = "${var.cluster_name}-cluster-sg"
  }
}

# --------------------------------------------------------------------------------------------------
#                               EKS cluster resource
# --------------------------------------------------------------------------------------------------
resource "aws_eks_cluster" "eks" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    endpoint_private_access = var.endpoint_private_access                           # Enable private access to the API server
    endpoint_public_access  = var.endpoint_public_access                            # Enable public access to the API server
    subnet_ids              = concat(var.private_subnet_ids, var.public_subnet_ids) # List of subnets for the EKS cluster
    security_group_ids      = [aws_security_group.eks_cluster.id]                   # Security group for the EKS cluster
  }

  # Adds API authentication mode and allows automatic admin access to the cluster creator.
  access_config {
    authentication_mode                         = true # Authentication using API
    bootstrap_cluster_creator_admin_permissions = true # provide admin permission to user who created the cluster
  }

  # Ensure the EKS cluster is created after the IAM roles and policies are in place
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy_attachment,
    aws_iam_role_policy_attachment.eks_vpc_resource_controller
  ]

  enabled_cluster_log_types = ["api", "audit"]
  tags = {
    Name = "${var.cluster_name}-eks-cluster"
  }
}

# --------------------------------------------------------------------------------------------------
#                               Node Group IAM roles and policies
# --------------------------------------------------------------------------------------------------
resource "aws_iam_role" "eks_node_group_role" {
  name = "${var.cluster_name}-node-group"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "sts:AssumeRole", # Allows EC2 instances to assume this role
        Principal = {
          Service = "ec2.amazonaws.com" # Allowed for EC2 instances (EKS worker nodes)
        }
      }
    ]
  })
  tags = {
    Name = "${var.cluster_name}-node-group-role"
  }
}

# Прив'язка політики для EKS Worker Nodes
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group_role.name
}

# Прив'язка політики для Amazon VPC CNI плагіну
resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group_role.name
}

# Прив'язка політики для читання з Amazon ECR
resource "aws_iam_role_policy_attachment" "ec2_container_registry_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_security_group" "eks_node_group" {
  name        = "${var.cluster_name}-node-group-sg"
  description = "Security group for EKS node group"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic from EKS node group to other resources"
  }
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
    description = "Allow node to node communication"
  }

  ingress {
    from_port       = 1025
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster.id]
    description     = "Allow communication from control plane to nodes"
  }

  tags = {
    Name                                        = "${var.cluster_name}-node-group-sg"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}
# --------------------------------------------------------------------------------------------------
#               Node group for EKS
# --------------------------------------------------------------------------------------------------
resource "aws_eks_node_group" "general" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = var.node_group_name
  node_role_arn   = aws_iam_role.eks_node_group_role.arn
  subnet_ids      = var.private_subnet_ids # Worker nodes are typically placed in private subnets for better security

  instance_types = var.node_instance_types
  disk_size      = var.node_disk_size

  scaling_config {
    desired_size = var.node_desired_size
    max_size     = var.node_max_size
    min_size     = var.node_min_size
  }
  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }

  update_config {
    max_unavailable = 1 # Minimum number of nodes that can be unavailable during an update (for rolling updates)
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.ec2_container_registry_read_only
  ]

  tags = {
    Name = "${var.cluster_name}-node-group"
  }

  # Add a custom tag to identify the role of the node group (e.g., "general" for general-purpose nodes)
  labels = {
    role = "general"
  }
}
