
output "namespace" {
  description = "Kubernetes namespace for monitoring components"
  value       = kubernetes_namespace.monitoring.metadata[0].name
}

output "prometheus_release_name" {
  description = "Helm release name for kube-prometheus-stack"
  value       = helm_release.prometheus.name
}

output "grafana_release_name" {
  description = "Helm release name for Grafana"
  value       = helm_release.grafana.name
}

output "grafana_service_name" {
  description = "Kubernetes Service name for Grafana (use with kubectl port-forward)"
  value       = var.grafana_release_name
}
