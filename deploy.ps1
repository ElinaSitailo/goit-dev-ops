# -----------------------------------------------------------------------
# Usage:
#   . .\env.ps1
#   .\deploy.ps1
# -----------------------------------------------------------------------

# Validate required env vars
if (-not $env:TF_VAR_database_password) { Write-Error "TF_VAR_database_password is not set. Run: . .\env.ps1"; exit 1 }
if (-not $env:TF_VAR_django_allowed_hosts) { Write-Error "TF_VAR_django_allowed_hosts is not set. Run: . .\env.ps1"; exit 1 }

function ok($msg)   { Write-Host "[OK] $msg" -ForegroundColor Green }
function info($msg) { Write-Host "[*]  $msg" -ForegroundColor Yellow }
function err($msg)  { Write-Host "[X]  $msg" -ForegroundColor Red; exit 1 }

function Show-HelmFailureDiagnostics {
  Write-Host ""
  Write-Host "-------------------------------------------------------------------"
  Write-Host "  Helm deploy diagnostics" -ForegroundColor Red
  Write-Host "-------------------------------------------------------------------"

  info "Helm release status"
  helm status django-app

  info "Pods overview"
  kubectl get pods -o wide

  info "StatefulSet status"
  kubectl get statefulset django-app-postgresql -o wide 2>$null

  info "Deployment status"
  kubectl get deployment django-app-django -o wide 2>$null

  info "Recent warning events"
  kubectl get events --sort-by=.lastTimestamp 2>$null | Select-Object -Last 30

  info "PostgreSQL pod logs (if present)"
  kubectl logs statefulset/django-app-postgresql --tail=80 2>$null

  info "Django pod logs (if present)"
  kubectl logs deployment/django-app-django --tail=80 2>$null

  Write-Host "-------------------------------------------------------------------"
}

function Invoke-HelmUpgradeOrInstall {
  $output = & helm upgrade --install django-app ./charts/django-app `
    --set image.repository="$ECR_URL" `
    --set image.tag="latest" `
    --set secret.databasePassword="$env:TF_VAR_database_password" `
    --set postgresql.auth.password="$env:TF_VAR_database_password" `
    --set config.DJANGO_ALLOWED_HOSTS="$env:TF_VAR_django_allowed_hosts" `
    --wait --timeout=600s 2>&1

  return [PSCustomObject]@{
    ExitCode = $LASTEXITCODE
    Output   = ($output | Out-String)
  }
}

Write-Host "-------------------------------------------------------------------"
Write-Host "              Django app full deployment"
Write-Host "-------------------------------------------------------------------"

# -----------------------------------------------------------------------
#               Terraform
# -----------------------------------------------------------------------
info "Running terraform apply..."
terraform apply -auto-approve
if ($LASTEXITCODE -ne 0) { err "terraform apply failed" }
ok "Terraform apply complete"

$ECR_URL      = (terraform output -raw ecr_repository_url)
$CLUSTER_NAME = (terraform output -raw eks_cluster_name)

ok "ECR URL: $ECR_URL"
ok "EKS cluster: $CLUSTER_NAME"

# -----------------------------------------------------------------------
#               Docker build and push to ECR
# -----------------------------------------------------------------------
info "Authenticating Docker to ECR..."
$ECR_REGISTRY = $ECR_URL.Split("/")[0]
$ECR_TOKEN = (aws ecr get-login-password --region eu-north-1)
if ($LASTEXITCODE -ne 0) { err "Failed to get ECR login token" }
docker login --username AWS --password $ECR_TOKEN $ECR_REGISTRY
if ($LASTEXITCODE -ne 0) { err "Docker ECR login failed" }
ok "Docker authenticated"

info "Building Docker image..."
docker build -t "${ECR_URL}:latest" ./app
if ($LASTEXITCODE -ne 0) { err "Docker build failed" }
ok "Docker image built"

info "Pushing image to ECR..."
docker push "${ECR_URL}:latest"
if ($LASTEXITCODE -ne 0) { err "Docker push failed" }
ok "Image pushed to ECR"

# -----------------------------------------------------------------------
#               Configure kubectl
# -----------------------------------------------------------------------
info "Updating kubeconfig for cluster $CLUSTER_NAME..."
aws eks update-kubeconfig --name $CLUSTER_NAME --region eu-north-1
if ($LASTEXITCODE -ne 0) { err "kubeconfig update failed" }
ok "kubeconfig updated"

# -----------------------------------------------------------------------
#               Helm deploy
# -----------------------------------------------------------------------
info "Updating Helm dependencies..."
helm dependency update ./charts/django-app
if ($LASTEXITCODE -ne 0) { err "helm dependency update failed" }
ok "Helm dependencies updated"

info "Deploying django-app via Helm..."
$helmResult = Invoke-HelmUpgradeOrInstall

if ($helmResult.ExitCode -ne 0) {
  Write-Host $helmResult.Output

  if ($helmResult.Output -match "StatefulSet\.apps.+is invalid: spec: Forbidden: updates to statefulset spec") {
    info "Detected immutable StatefulSet spec change. Recreating Helm release..."

    helm uninstall django-app
    if ($LASTEXITCODE -ne 0) { err "Failed to uninstall existing django-app release" }

    $helmResult = Invoke-HelmUpgradeOrInstall
    if ($helmResult.ExitCode -ne 0) {
      Write-Host $helmResult.Output
      Show-HelmFailureDiagnostics
      err "Helm deploy failed after release recreation"
    }
  }
  else {
    Show-HelmFailureDiagnostics
    err "Helm deploy failed"
  }
}
ok "Helm deploy complete"

# -----------------------------------------------------------------------
#               Summary
# -----------------------------------------------------------------------
Write-Host ""
Write-Host "-------------------------------------------------------------------"
Write-Host "  Deployment complete!" -ForegroundColor Green
Write-Host "  ECR:     $ECR_URL"
Write-Host "  Cluster: $CLUSTER_NAME"
$EXTERNAL_IP = kubectl get svc django-app-django -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>$null
if (-not $EXTERNAL_IP) { $EXTERNAL_IP = "pending..." }
Write-Host "  App URL: http://$EXTERNAL_IP"
Write-Host "-------------------------------------------------------------------"
