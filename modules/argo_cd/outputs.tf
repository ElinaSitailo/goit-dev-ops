output "namespace" {
  description = "Argo CD namespace"
  value       = kubernetes_namespace.argocd.metadata[0].name
}

output "release_name" {
  description = "Argo CD Helm release name"
  value       = helm_release.argocd.name
}

output "application_name" {
  description = "Argo CD Application name"
  value       = var.application_name
}

output "server_service_name" {
  description = "Kubernetes Service name for Argo CD API/UI"
  value       = data.kubernetes_service.argocd_server.metadata[0].name
}

output "server_external_hostname" {
  description = "External DNS hostname for Argo CD server service (when LoadBalancer is provisioned)"
  value       = try(data.kubernetes_service.argocd_server.status[0].load_balancer[0].ingress[0].hostname, null)
}

output "server_external_ip" {
  description = "External IP for Argo CD server service (when LoadBalancer is provisioned)"
  value       = try(data.kubernetes_service.argocd_server.status[0].load_balancer[0].ingress[0].ip, null)
}
