# -----------------------------------------------------------------------
# Usage:
#   . .\env.ps1
#   .\deploy.ps1
# -----------------------------------------------------------------------

# Validate required env vars
if (-not $env:AWS_ACCESS_KEY_ID) { Write-Error "AWS_ACCESS_KEY_ID is not set. Run: . .\env.ps1"; exit 1 }
if (-not $env:AWS_SECRET_ACCESS_KEY) { Write-Error "AWS_SECRET_ACCESS_KEY is not set. Run: . .\env.ps1"; exit 1 }
if (-not $env:TF_VAR_aws_access_key_id) { Write-Error "TF_VAR_aws_access_key_id is not set. Run: . .\env.ps1"; exit 1 }
if (-not $env:TF_VAR_aws_secret_access_key) { Write-Error "TF_VAR_aws_secret_access_key is not set. Run: . .\env.ps1"; exit 1 }
if (-not $env:TF_VAR_database_password) { Write-Error "TF_VAR_database_password is not set. Run: . .\env.ps1"; exit 1 }
if (-not $env:TF_VAR_django_allowed_hosts) { Write-Error "TF_VAR_django_allowed_hosts is not set. Run: . .\env.ps1"; exit 1 }
if (-not $env:TF_VAR_django_secret_key) { Write-Error "TF_VAR_django_secret_key is not set. Run: . .\env.ps1"; exit 1 }
if (-not $env:TF_VAR_jenkins_admin_password) { Write-Error "TF_VAR_jenkins_admin_password is not set. Run: . .\env.ps1"; exit 1 }
if (-not $env:TF_VAR_jenkins_gitops_username) { Write-Error "TF_VAR_jenkins_gitops_username is not set. Run: . .\env.ps1"; exit 1 }
if (-not $env:TF_VAR_jenkins_gitops_token) { Write-Error "TF_VAR_jenkins_gitops_token is not set. Run: . .\env.ps1"; exit 1 }
if (-not $env:TF_VAR_argocd_application_repo_url) { Write-Error "TF_VAR_argocd_application_repo_url is not set. Run: . .\env.ps1"; exit 1 }

function ok($msg)   { Write-Host "[OK] $msg" -ForegroundColor Green }
function info($msg) { Write-Host "[*]  $msg" -ForegroundColor Yellow }
function err($msg)  { Write-Host "[X]  $msg" -ForegroundColor Red; exit 1 }

Write-Host "-------------------------------------------------------------------"
Write-Host "              Infrastructure deployment"
Write-Host "  Docker build/push -> Jenkins"
Write-Host "  App rollout        -> Argo CD"
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
$AWS_REGION   = (terraform output -raw aws_region)

ok "ECR URL: $ECR_URL"
ok "EKS cluster: $CLUSTER_NAME"

# -----------------------------------------------------------------------
#               Configure kubectl
# -----------------------------------------------------------------------
info "Updating kubeconfig for cluster $CLUSTER_NAME..."
aws eks update-kubeconfig --name $CLUSTER_NAME --region $AWS_REGION
if ($LASTEXITCODE -ne 0) { err "kubeconfig update failed" }
ok "kubeconfig updated"

# -----------------------------------------------------------------------
#               Collect Jenkins and Argo CD endpoints
# -----------------------------------------------------------------------
info "Waiting for Jenkins LoadBalancer hostname..."
$JenkinsHost = ""
for ($i = 0; $i -lt 40; $i++) {
  $JenkinsHost = & terraform output -raw jenkins_service_external_hostname 2>$null
  if ($JenkinsHost -and $JenkinsHost -ne "null") { break }
  Start-Sleep -Seconds 15
}
if (-not $JenkinsHost -or $JenkinsHost -eq "null") {
  err "Jenkins LoadBalancer hostname did not provision within the timeout. Check: kubectl get svc -n jenkins"
}

info "Waiting for Argo CD LoadBalancer hostname..."
$ArgoCDHost = ""
for ($i = 0; $i -lt 40; $i++) {
  $ArgoCDHost = & terraform output -raw argocd_server_external_hostname 2>$null
  if ($ArgoCDHost -and $ArgoCDHost -ne "null") { break }
  Start-Sleep -Seconds 15
}
if (-not $ArgoCDHost -or $ArgoCDHost -eq "null") {
  err "Argo CD LoadBalancer hostname did not provision within the timeout. Check: kubectl get svc -n argocd"
}

# -----------------------------------------------------------------------
#               Summary
# -----------------------------------------------------------------------
Write-Host ""
Write-Host "-------------------------------------------------------------------"
Write-Host "  Infrastructure ready!" -ForegroundColor Green
Write-Host "  ECR:         $ECR_URL"
Write-Host "  EKS cluster: $CLUSTER_NAME"
Write-Host ""
Write-Host "  Jenkins:  http://$JenkinsHost" -ForegroundColor Cyan
Write-Host "  Argo CD:  http://$ArgoCDHost" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Next steps:" -ForegroundColor Yellow
Write-Host "    1. Open Jenkins UI and add credentials:"
Write-Host "         aws-jenkins        (AWS Credentials)"
Write-Host "         gitops-repo-token  (Username/Password - GitHub PAT)"
Write-Host "    2. Create a Pipeline job in Jenkins pointing to this repo (Jenkinsfile)."
Write-Host "    3. Run the pipeline - it will build the image, push to ECR, update values.yaml."
Write-Host "    4. Argo CD will auto-sync and deploy the app to the cluster."
Write-Host "    5. Check Argo CD Application status:"
Write-Host "         kubectl get application django-app -n argocd"
Write-Host "-------------------------------------------------------------------"
