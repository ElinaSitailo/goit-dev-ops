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

resource "aws_security_group_rule" "cluster_ingress_from_nodes" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster.id
  source_security_group_id = aws_security_group.eks_node_group.id
  description              = "Allow nodes to reach the API server"
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
    authentication_mode                         = "API" # Authentication using API
    bootstrap_cluster_creator_admin_permissions = true  # provide admin permission to user who created the cluster
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

  tags = {
    Name                                        = "${var.cluster_name}-node-group-sg"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

resource "aws_security_group_rule" "nodes_ingress_self" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self              = true
  security_group_id = aws_security_group.eks_node_group.id
  description       = "Allow node to node communication"
}

resource "aws_security_group_rule" "nodes_ingress_from_cluster" {
  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_node_group.id
  source_security_group_id = aws_security_group.eks_cluster.id
  description              = "Allow communication from control plane to nodes"
}
# --------------------------------------------------------------------------------------------------
#               Node group for EKS
# --------------------------------------------------------------------------------------------------

# The EKS node group is created using an EC2 launch template, 
# which allows for more flexible configuration of the worker nodes.
# It binds aws_security_group.eks_node_group with aws_eks_node_group.general
# to allow communication between the control plane and worker nodes, 
# as well as between the worker nodes themselves.
resource "aws_launch_template" "eks_node_group" {
  name_prefix = "${var.cluster_name}-node-group-"

  vpc_security_group_ids = [aws_security_group.eks_node_group.id]

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.node_disk_size
      volume_type           = "gp3"
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.cluster_name}-node"
    }
  }
}

resource "aws_eks_node_group" "general" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = var.node_group_name
  node_role_arn   = aws_iam_role.eks_node_group_role.arn
  subnet_ids      = var.private_subnet_ids # Worker nodes are typically placed in private subnets for better security

  instance_types = var.node_instance_types

  launch_template {
    id      = aws_launch_template.eks_node_group.id
    version = aws_launch_template.eks_node_group.latest_version
  }

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

# --------------------------------------------------------------------------------------------------
#   EBS CSI Driver — required for PersistentVolumes on Kubernetes 1.23+
# --------------------------------------------------------------------------------------------------

data "aws_iam_policy" "ebs_csi_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

data "tls_certificate" "eks_oidc" {
  url = aws_eks_cluster.eks.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_oidc.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.eks.identity[0].oidc[0].issuer
}

data "aws_iam_policy_document" "ebs_csi_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }
  }
}

resource "aws_iam_role" "ebs_csi_driver" {
  name               = "${var.cluster_name}-ebs-csi-driver"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver" {
  role       = aws_iam_role.ebs_csi_driver.name
  policy_arn = data.aws_iam_policy.ebs_csi_policy.arn
}

resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name             = aws_eks_cluster.eks.name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = aws_iam_role.ebs_csi_driver.arn

  depends_on = [aws_eks_node_group.general]
}
