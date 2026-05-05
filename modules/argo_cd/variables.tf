variable "namespace" {
  description = "Kubernetes namespace for Argo CD"
  type        = string
  default     = "argocd"
}

variable "release_name" {
  description = "Helm release name for Argo CD"
  type        = string
  default     = "argocd"
}

variable "application_name" {
  description = "Argo CD Application name"
  type        = string
}

variable "application_repo_url" {
  description = "Git repository URL monitored by Argo CD"
  type        = string
}

variable "application_target_revision" {
  description = "Git branch or revision monitored by Argo CD"
  type        = string
  default     = "main"
}

variable "application_path" {
  description = "Path to Helm chart in the monitored repository"
  type        = string
}

variable "application_destination_ns" {
  description = "Namespace where Argo CD deploys the application"
  type        = string
  default     = "default"
}

variable "server_service_name" {
  description = "Argo CD server service name to read external endpoint from"
  type        = string
  default     = "argocd-server"
}

variable "database_password" {
  description = "Django app database password (passed as Helm value to the app)"
  type        = string
  sensitive   = true
}

variable "django_secret_key" {
  description = "Django SECRET_KEY (passed as Helm value to the app)"
  type        = string
  sensitive   = true
}

variable "django_allowed_hosts" {
  description = "Django ALLOWED_HOSTS value (passed as Helm value to the app)"
  type        = string
}

variable "server_insecure" {
  description = "Disable TLS on the Argo CD API/UI endpoint. Set true only for dev; use an ingress with TLS in production."
  type        = bool
  default     = false
}
