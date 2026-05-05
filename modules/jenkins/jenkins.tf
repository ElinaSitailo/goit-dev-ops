resource "kubernetes_namespace" "jenkins" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "jenkins" {
  name             = var.release_name
  repository       = "https://charts.jenkins.io"
  chart            = "jenkins"
  version          = "5.9.18"
  namespace        = kubernetes_namespace.jenkins.metadata[0].name
  create_namespace = false
  wait             = true
  timeout          = 1200

  values = [
    <<-YAML
    controller:
      admin:
        username: "${var.admin_username}"
        password: "${var.admin_password}"
      serviceType: LoadBalancer
      resources:
        requests:
          cpu: "500m"
          memory: "512Mi"
        limits:
          cpu: "2000m"
          memory: "2048Mi"
      installPlugins:
        - kubernetes
        - workflow-aggregator
        - git
        - configuration-as-code
        - credentials-binding
        - aws-credentials
      installLatestPlugins: true
      initializeOnce: true
      JCasC:
        configScripts:
          kubernetes: |
            jenkins:
              clouds:
                - kubernetes:
                    name: "kubernetes"
                    serverUrl: "https://kubernetes.default"
                    namespace: "${var.namespace}"
                    jenkinsUrl: "http://${var.release_name}.${var.namespace}.svc.cluster.local:8080"
                    jenkinsTunnel: "${var.release_name}-agent.${var.namespace}.svc.cluster.local:50000"
                    templates:
                      - name: "kaniko-git"
                        namespace: "${var.namespace}"
                        label: "kaniko-git"
                        serviceAccount: "jenkins"
                        containers:
                          - name: "kaniko"
                            image: "gcr.io/kaniko-project/executor:v1.23.2-debug"
                            command: "cat"
                            ttyEnabled: true
                            workingDir: "/workspace"
                          - name: "git"
                            image: "alpine/git:2.47.2"
                            command: "cat"
                            ttyEnabled: true
                            workingDir: "/workspace"
                          - name: "aws-cli"
                            image: "amazon/aws-cli:2.22.35"
                            command: "cat"
                            ttyEnabled: true
                            workingDir: "/workspace"
          credentials: |
            credentials:
              system:
                domainCredentials:
                  - credentials:
                      - aws:
                          scope: GLOBAL
                          id: "aws-jenkins"
                          description: "AWS credentials for ECR and EKS access"
                          accessKey: "${var.aws_access_key_id}"
                          secretKey: "${var.aws_secret_access_key}"
                      - usernamePassword:
                          scope: GLOBAL
                          id: "gitops-repo-token"
                          description: "GitHub PAT for GitOps repository"
                          username: "${var.gitops_username}"
                          password: "${var.gitops_token}"
    persistence:
      enabled: true
      storageClass: "gp2"
      size: 8Gi
    serviceAccount:
      create: true
      name: jenkins
    rbac:
      create: true
    YAML
  ]

  depends_on = [kubernetes_namespace.jenkins]
}

data "kubernetes_service" "jenkins_controller" {
  metadata {
    name      = var.release_name
    namespace = kubernetes_namespace.jenkins.metadata[0].name
  }

  depends_on = [helm_release.jenkins]
}
