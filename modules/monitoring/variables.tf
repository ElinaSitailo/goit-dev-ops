
variable "namespace" {
  description = "Kubernetes namespace for Prometheus and Grafana"
  type        = string
  default     = "monitoring"
}

# -----------------------------------------------------------------------
#               Prometheus
# -----------------------------------------------------------------------

variable "prometheus_release_name" {
  description = "Helm release name for kube-prometheus-stack"
  type        = string
  default     = "prometheus"
}

variable "prometheus_storage_size" {
  description = "PersistentVolumeClaim size for Prometheus TSDB"
  type        = string
  default     = "10Gi"
}

# -----------------------------------------------------------------------
#               Grafana
# -----------------------------------------------------------------------

variable "grafana_release_name" {
  description = "Helm release name for Grafana"
  type        = string
  default     = "grafana"
}

variable "grafana_admin_user" {
  description = "Grafana admin username"
  type        = string
  default     = "admin"
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
}

variable "grafana_storage_size" {
  description = "PersistentVolumeClaim size for Grafana"
  type        = string
  default     = "5Gi"
}
