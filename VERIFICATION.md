# Deployment Verification Guide

Step-by-step checks to confirm every layer of the stack is healthy after running `.\deploy.ps1`.

---

## Prerequisites

```powershell
# Load environment variables if not already loaded
. .\env.ps1

# Confirm kubectl is pointing at the right cluster
kubectl config current-context
# Expected output contains: lesson-7-eks

# If kubeconfig is missing, update it manually
aws eks update-kubeconfig --region eu-north-1 --name lesson-7-eks
```

---

## Step 1 — Terraform Outputs

Confirm Terraform completed successfully and all key outputs are populated.

```powershell
terraform output
```

Every value below must be non-empty:

| Output | What to look for |
|--------|-----------------|
| `ecr_repository_url` | `<account_id>.dkr.ecr.eu-north-1.amazonaws.com/lesson-5-ecr` |
| `eks_cluster_name` | `lesson-7-eks` |
| `eks_cluster_endpoint` | `https://...` URL |
| `jenkins_service_external_hostname` | AWS ELB hostname (long DNS name) |
| `argocd_server_external_hostname` | AWS ELB hostname |
| `vpc_public_subnet_ids` | List of 3 subnet IDs |
| `vpc_private_subnet_ids` | List of 3 subnet IDs |

---

## Step 2 — EKS Cluster Nodes

```powershell
kubectl get nodes -o wide
```

Expected: **2 nodes** in `Ready` state, instance type `t3.medium`, placed in private subnets.

```
NAME                                        STATUS   ROLES    AGE   VERSION
ip-10-0-4-xxx.eu-north-1.compute.internal   Ready    <none>   ...   v1.32.x
ip-10-0-5-xxx.eu-north-1.compute.internal   Ready    <none>   ...   v1.32.x
```

If nodes are `NotReady`, check node group status:

```powershell
aws eks describe-nodegroup `
  --cluster-name lesson-7-eks `
  --nodegroup-name lesson-7-nodes `
  --query "nodegroup.status"
```

Expected: `"ACTIVE"`

---

## Step 3 — ECR Repository

Confirm the repository exists and is reachable.

```powershell
aws ecr describe-repositories `
  --repository-names lesson-5-ecr `
  --region eu-north-1 `
  --query "repositories[0].repositoryUri"
```

Expected: non-empty URI string.

After the first Jenkins build runs, verify images are present:

```powershell
aws ecr list-images `
  --repository-name lesson-5-ecr `
  --region eu-north-1 `
  --query "imageIds[*].imageTag"
```

Expected: at least `latest` and a versioned tag in `<build_number>-<7-char-sha>` format, e.g. `3-a1b2c3d`.

---

## Step 4 — Jenkins

### 4a. Pod is running

```powershell
kubectl get pods -n jenkins
```

Expected: one pod with name `jenkins-0`, status `Running`, all containers `Ready`.

```
NAME        READY   STATUS    RESTARTS   AGE
jenkins-0   2/2     Running   0          ...
```

### 4b. Service has a hostname

```powershell
kubectl get svc -n jenkins
```

The `jenkins` service must show an `EXTERNAL-IP` value (AWS ELB DNS hostname, not `<pending>`).

```
NAME      TYPE           CLUSTER-IP   EXTERNAL-IP                        PORT(S)
jenkins   LoadBalancer   10.x.x.x     xxxx.eu-north-1.elb.amazonaws.com  8080:...
```

> If `EXTERNAL-IP` stays `<pending>` for more than 5 minutes, check that the subnets are tagged with `kubernetes.io/role/elb=1`.

### 4c. UI is reachable

```powershell
$JenkinsHost = terraform output -raw jenkins_service_external_hostname
Start-Process "http://${JenkinsHost}:8080"
```

Login with username `admin` and the password from `TF_VAR_jenkins_admin_password`.

### 4d. Credentials are pre-seeded

In the Jenkins UI: **Manage Jenkins → Credentials → System → Global credentials**.

Both credentials below must exist — they are provisioned automatically by JCasC:

| ID | Type |
|----|------|
| `aws-jenkins` | AWS Credentials |
| `gitops-repo-token` | Username/Password |

### 4e. Kubernetes cloud is configured

**Manage Jenkins → Clouds** — a cloud named `kubernetes` must be present with:
- Server URL: `https://kubernetes.default`
- Namespace: `jenkins`
- Pod template label: `kaniko-git`

---

## Step 5 — Argo CD

### 5a. Pods are running

```powershell
kubectl get pods -n argocd
```

Expected: all pods `Running` or `Completed`. Key pods:

```
argocd-application-controller-0   1/1   Running
argocd-repo-server-xxx             1/1   Running
argocd-server-xxx                  1/1   Running
argocd-redis-xxx                   1/1   Running
```

### 5b. Service has a hostname

```powershell
kubectl get svc argocd-server -n argocd
```

`EXTERNAL-IP` must be populated (same as `terraform output argocd_server_external_hostname`).

### 5c. Application resource exists

```powershell
kubectl get application django-app -n argocd
```

Expected columns:

| HEALTH | SYNC | MESSAGE |
|--------|------|---------|
| `Healthy` | `Synced` | — |

If SYNC is `OutOfSync`, force a manual sync:

```powershell
kubectl patch application django-app -n argocd `
  --type merge `
  -p '{"operation":{"sync":{"revision":"HEAD"}}}'
```

### 5d. UI is reachable

```powershell
$ArgoCDHost = terraform output -raw argocd_server_external_hostname
Start-Process "http://${ArgoCDHost}"
```

Default credentials: username `admin`, password retrieved with:

```powershell
kubectl get secret argocd-initial-admin-secret -n argocd `
  -o jsonpath="{.data.password}" | `
  [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($_))
```

In the UI, open the `django-app` application and confirm:
- Status: **Synced** and **Healthy**
- Repository: matches `TF_VAR_argocd_application_repo_url`
- Target revision: `main`
- Path: `charts/django-app`

---

## Step 6 — Django Application

### 6a. Pods are running

```powershell
kubectl get pods -n default
```

Expected: at least one `django-app-django-xxx` pod in `Running` state and one `django-app-postgresql-0` pod.

```
NAME                               READY   STATUS    RESTARTS
django-app-django-xxx-yyy          1/1     Running   0
django-app-postgresql-0            1/1     Running   0
```

If pods are in `Init:0/1`, the init container is still waiting for PostgreSQL — this is normal for up to ~60 seconds.

### 6b. Service has a hostname

```powershell
kubectl get svc django-app-django -n default
```

`EXTERNAL-IP` must be populated.

### 6c. Health endpoint responds

```powershell
$AppHost = kubectl get svc django-app-django -n default `
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

Invoke-RestMethod "http://${AppHost}/health/"
```

Expected response (HTTP 200):

```json
{"status": "ok", "db": true}
```

If `"db": false` (HTTP 503), the app is running but cannot reach PostgreSQL — check `django-app-postgresql-0` pod logs:

```powershell
kubectl logs django-app-postgresql-0 -n default
```

### 6d. HPA is active

```powershell
kubectl get hpa -n default
```

Expected:

```
NAME               REFERENCE                      TARGETS   MINPODS   MAXPODS   REPLICAS
django-app-django  Deployment/django-app-django   <x>%/80%  1         6         1
```

`TARGETS` should show a CPU percentage rather than `<unknown>`. If it shows `<unknown>`, verify the metrics-server is running:

```powershell
kubectl get pods -n kube-system | Select-String "metrics-server"
```

---

## Step 7 — End-to-End Pipeline Smoke Test

This step verifies the complete CI/CD flow: code change → Jenkins build → ECR push → GitOps commit → Argo CD sync → new pod.

### 7a. Create a Jenkins Pipeline job

1. In the Jenkins UI click **New Item → Pipeline**.
2. Name it `django-app`.
3. Under **Pipeline**, select **Pipeline script from SCM**.
4. Set SCM to **Git**, URL to this repository.
5. Set **Branch** to `*/main`.
6. Set **Script Path** to `Jenkinsfile`.
7. Under **Build Triggers**, enable **Poll SCM** with schedule `H/5 * * * *` (every 5 minutes).
8. Click **Save**.

### 7b. Trigger a build manually

In the Jenkins UI, click **Build with Parameters**:

| Parameter | Value |
|-----------|-------|
| `ECR_REPOSITORY` | output of `terraform output -raw ecr_repository_url` |
| `GITOPS_REPO_URL` | your GitOps repo URL |
| `GITOPS_BRANCH` | `main` |
| `GITOPS_VALUES_FILE` | `charts/django-app/values.yaml` |

### 7c. Verify each build stage passed

In the build console output, confirm these stages completed without error:

```
[Stage 1] Checkout Source     → IMAGE_TAG = <n>-<sha>
[Stage 2] ECR Auth            → docker config written
[Stage 3] Build and Push      → Pushed to ECR: <tag> and latest
[Stage 4] Update GitOps repo  → Committed: ci: update django image tag to <tag>
```

### 7d. Verify the GitOps commit

In your GitOps repository, check that `charts/django-app/values.yaml` now contains:

```yaml
image:
  tag: "<n>-<sha>"
```

### 7e. Verify Argo CD synced the new tag

```powershell
kubectl get application django-app -n argocd -o jsonpath='{.status.sync.revision}'
```

This must match the commit SHA from step 7d.

```powershell
kubectl get deployment django-app-django -n default `
  -o jsonpath='{.spec.template.spec.containers[0].image}'
```

The image tag in the Deployment must match `IMAGE_TAG` from the Jenkins build.

### 7f. Confirm the app is still healthy

```powershell
Invoke-RestMethod "http://${AppHost}/health/"
# Expected: {"status": "ok", "db": true}
```

---

## Quick Reference — Common Failure Checks

| Symptom | Command | What to look for |
|---------|---------|-----------------|
| Node not Ready | `kubectl describe node <name>` | Events section for disk/memory pressure |
| Jenkins pod crash-looping | `kubectl logs jenkins-0 -n jenkins -c jenkins` | OOM or config errors |
| Argo CD OutOfSync forever | `kubectl describe application django-app -n argocd` | `conditions` and `operationState` fields |
| App pod ImagePullBackOff | `kubectl describe pod <name> -n default` | ECR auth or wrong image tag |
| Health returns `"db": false` | `kubectl logs django-app-postgresql-0` | PostgreSQL startup errors |
| LoadBalancer stuck `<pending>` | `kubectl describe svc <name>` | Events — usually missing subnet tags |
| Kaniko build fails | Jenkins build console | Check `aws-jenkins` credential scope and ECR repository policy |
