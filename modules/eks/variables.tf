# -----------------------------------------------------------------------
#               Cluster
# -----------------------------------------------------------------------

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_-]{0,99}$", var.cluster_name))
    error_message = "Cluster name must start with a letter and contain only letters, numbers, hyphens, or underscores (max 100 chars)."
  }
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster (e.g. \"1.29\")"
  type        = string
}

# -----------------------------------------------------------------------
#               Networking
# -----------------------------------------------------------------------

variable "vpc_id" {
  description = "ID of the VPC where the EKS cluster will be created"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for EKS worker nodes"
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_ids) >= 1
    error_message = "At least one private subnet ID must be provided."
  }
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for the EKS control plane ENIs"
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_ids) >= 1
    error_message = "At least one public subnet ID must be provided."
  }
}

variable "endpoint_private_access" {
  description = "Whether to enable private access to the EKS API server (true/false)"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Whether to enable public access to the EKS API server (true/false)"
  type        = bool
  default     = true
}
# -----------------------------------------------------------------------
#               Node Group
# -----------------------------------------------------------------------

variable "node_group_name" {
  description = "Name of the EKS managed node group"
  type        = string
}

variable "node_instance_types" {
  description = "List of EC2 instance types for the node group"
  type        = list(string)

  validation {
    condition     = length(var.node_instance_types) >= 1
    error_message = "At least one instance type must be specified."
  }
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number

  validation {
    condition     = var.node_desired_size >= 1
    error_message = "Desired node count must be at least 1."
  }
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number

  validation {
    condition     = var.node_min_size >= 1
    error_message = "Minimum node count must be at least 1."
  }
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number

  validation {
    condition     = var.node_max_size >= var.node_min_size
    error_message = "Maximum node count must be greater than or equal to the minimum node count."
  }
}

variable "node_disk_size" {
  description = "Disk size (in GB) for each worker node"
  type        = number
  default     = 20
}
