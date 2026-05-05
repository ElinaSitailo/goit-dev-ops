variable "namespace" {
  description = "Kubernetes namespace for Jenkins"
  type        = string
  default     = "jenkins"
}

variable "release_name" {
  description = "Helm release name for Jenkins"
  type        = string
  default     = "jenkins"
}

variable "admin_username" {
  description = "Jenkins admin username"
  type        = string
  default     = "admin"
}

variable "admin_password" {
  description = "Jenkins admin password"
  type        = string
  sensitive   = true
}

variable "aws_access_key_id" {
  description = "AWS access key ID for the aws-jenkins credential in Jenkins"
  type        = string
  sensitive   = true
}

variable "aws_secret_access_key" {
  description = "AWS secret access key for the aws-jenkins credential in Jenkins"
  type        = string
  sensitive   = true
}

variable "gitops_username" {
  description = "GitHub username for the gitops-repo-token credential in Jenkins"
  type        = string
}

variable "gitops_token" {
  description = "GitHub PAT for the gitops-repo-token credential in Jenkins"
  type        = string
  sensitive   = true
}
