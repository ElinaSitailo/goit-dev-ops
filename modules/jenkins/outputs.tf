output "namespace" {
  description = "Jenkins namespace"
  value       = kubernetes_namespace.jenkins.metadata[0].name
}

output "release_name" {
  description = "Jenkins Helm release name"
  value       = helm_release.jenkins.name
}

output "service_name" {
  description = "Kubernetes Service name for Jenkins controller"
  value       = data.kubernetes_service.jenkins_controller.metadata[0].name
}

output "service_external_hostname" {
  description = "External DNS hostname for Jenkins service (when LoadBalancer is provisioned)"
  value       = try(data.kubernetes_service.jenkins_controller.status[0].load_balancer[0].ingress[0].hostname, null)
}

output "service_external_ip" {
  description = "External IP for Jenkins service (when LoadBalancer is provisioned)"
  value       = try(data.kubernetes_service.jenkins_controller.status[0].load_balancer[0].ingress[0].ip, null)
}
