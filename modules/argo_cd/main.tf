resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "argocd" {
  name             = var.release_name
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "7.8.23"
  namespace        = kubernetes_namespace.argocd.metadata[0].name
  create_namespace = false
  wait             = true
  timeout          = 900

  values = [
    <<-YAML
    server:
      service:
        type: LoadBalancer
    configs:
      params:
        server.insecure: "${var.server_insecure}"
    crds:
      install: true
    YAML
  ]

  depends_on = [kubernetes_namespace.argocd]
}

resource "helm_release" "argocd_application" {
  name             = "${var.application_name}-apps"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argocd-apps"
  version          = "2.0.2"
  namespace        = kubernetes_namespace.argocd.metadata[0].name
  create_namespace = false
  wait             = true
  timeout          = 600

  values = [
    <<-YAML
    applications:
      ${var.application_name}:
        namespace: "${var.namespace}"
        project: default
        source:
          repoURL: "${var.application_repo_url}"
          targetRevision: "${var.application_target_revision}"
          path: "${var.application_path}"
          helm:
            values: |
              env:
                DATABASE_PASSWORD: "${var.database_password}"
                DJANGO_SECRET_KEY: "${var.django_secret_key}"
                ALLOWED_HOSTS: "${var.django_allowed_hosts}"
        destination:
          server: "https://kubernetes.default.svc"
          namespace: "${var.application_destination_ns}"
        syncPolicy:
          automated:
            prune: true
            selfHeal: true
          syncOptions:
            - CreateNamespace=true
    YAML
  ]

  depends_on = [helm_release.argocd]
}

data "kubernetes_service" "argocd_server" {
  metadata {
    name      = var.server_service_name
    namespace = kubernetes_namespace.argocd.metadata[0].name
  }

  depends_on = [helm_release.argocd]
}
