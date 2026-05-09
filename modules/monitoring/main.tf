
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.namespace
  }
}

# -----------------------------------------------------------------------
#               Prometheus  (kube-prometheus-stack)
# -----------------------------------------------------------------------

resource "helm_release" "prometheus" {
  name             = var.prometheus_release_name
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = "70.4.2"
  namespace        = kubernetes_namespace.monitoring.metadata[0].name
  create_namespace = false
  wait             = true
  timeout          = 900

  values = [
    <<-YAML
    prometheus:
      prometheusSpec:
        retention: 15d
        resources:
          requests:
            cpu: "200m"
            memory: "512Mi"
          limits:
            cpu: "500m"
            memory: "1Gi"
        storageSpec:
          volumeClaimTemplate:
            spec:
              storageClassName: gp2
              accessModes: ["ReadWriteOnce"]
              resources:
                requests:
                  storage: ${var.prometheus_storage_size}
    alertmanager:
      enabled: false
    grafana:
      enabled: false
    YAML
  ]

  depends_on = [kubernetes_namespace.monitoring]
}

# -----------------------------------------------------------------------
#               Grafana
# -----------------------------------------------------------------------

resource "helm_release" "grafana" {
  name             = var.grafana_release_name
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "grafana"
  version          = "8.10.4"
  namespace        = kubernetes_namespace.monitoring.metadata[0].name
  create_namespace = false
  wait             = true
  timeout          = 600

  values = [
    <<-YAML
    adminUser: "${var.grafana_admin_user}"
    adminPassword: "${var.grafana_admin_password}"

    service:
      type: ClusterIP
      port: 80

    persistence:
      enabled: true
      storageClassName: gp2
      size: ${var.grafana_storage_size}

    datasources:
      datasources.yaml:
        apiVersion: 1
        datasources:
          - name: Prometheus
            type: prometheus
            url: http://${var.prometheus_release_name}-kube-prometheus-prometheus.${var.namespace}.svc.cluster.local:9090
            access: proxy
            isDefault: true

    dashboardProviders:
      dashboardproviders.yaml:
        apiVersion: 1
        providers:
          - name: default
            orgId: 1
            folder: ''
            type: file
            disableDeletion: false
            editable: true
            options:
              path: /var/lib/grafana/dashboards/default

    dashboards:
      default:
        kubernetes-cluster:
          gnetId: 7249
          revision: 1
          datasource: Prometheus
        kubernetes-pods:
          gnetId: 6336
          revision: 1
          datasource: Prometheus
        node-exporter:
          gnetId: 1860
          revision: 37
          datasource: Prometheus

    resources:
      requests:
        cpu: "100m"
        memory: "128Mi"
      limits:
        cpu: "300m"
        memory: "256Mi"
    YAML
  ]

  depends_on = [helm_release.prometheus]
}
