provider "aws" {
  region  = var.main_aws_region

  default_tags {
    tags = {
      Project     = var.main_project
      Environment = var.main_environment
      ManagedBy   = "terraform"
    }
  }
}

module "s3_backend" {
  source = "./modules/s3-backend"

  aws_region  = var.main_aws_region
  environment = var.main_environment
  project     = var.main_project

  bucket_name       = var.s3_bucket_name
  table_name        = var.dynamodb_table_name
  enable_versioning = true
  force_destroy     = false
  table_hash_key    = "LockID"
}

module "vpc" {
  source = "./modules/vpc"

  name                 = var.vpc_name
  cidr_block           = var.vpc_cidr_block
  public_subnets       = var.vpc_public_subnets
  private_subnets      = var.vpc_private_subnets
  availability_zones   = var.vpc_availability_zones
  enable_dns_hostnames = true
  enable_dns_support   = true
}

module "ecr" {
  source = "./modules/ecr"

  name         = var.ecr_name
  scan_on_push = var.ecr_scan_on_push

  image_tag_mutability = var.ecr_image_tag_mutability
  encryption_type      = var.ecr_encryption_type
  max_image_count      = var.ecr_max_image_count
  force_delete         = var.ecr_force_delete
}

module "eks" {
  source = "./modules/eks"

  cluster_name    = var.eks_cluster_name
  cluster_version = var.eks_cluster_version

  vpc_id             = module.vpc.id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids

  endpoint_private_access = var.eks_endpoint_private_access
  endpoint_public_access  = var.eks_endpoint_public_access

  node_group_name     = var.eks_node_group_name
  node_instance_types = var.eks_node_instance_types
  node_desired_size   = var.eks_node_desired_size
  node_min_size       = var.eks_node_min_size
  node_max_size       = var.eks_node_max_size
  node_disk_size      = var.eks_node_disk_size
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", var.main_aws_region]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", var.main_aws_region]
    }
  }
}

module "jenkins" {
  source = "./modules/jenkins"

  namespace      = var.jenkins_namespace
  release_name   = var.jenkins_release_name
  admin_username = var.jenkins_admin_username
  admin_password = var.jenkins_admin_password

  aws_access_key_id     = var.aws_access_key_id
  aws_secret_access_key = var.aws_secret_access_key
  gitops_username       = var.jenkins_gitops_username
  gitops_token          = var.jenkins_gitops_token

  depends_on = [module.eks]
}

module "argo_cd" {
  source = "./modules/argo_cd"

  namespace                   = var.argocd_namespace
  release_name                = var.argocd_release_name
  application_name            = var.argocd_application_name
  application_repo_url        = var.argocd_application_repo_url
  application_target_revision = var.argocd_application_target_revision
  application_path            = var.argocd_application_path
  application_destination_ns  = var.argocd_application_destination_namespace
  server_service_name         = var.argocd_server_service_name
  server_insecure             = true # DEV ONLY — set false behind an ingress with TLS in production

  database_password    = var.database_password
  django_secret_key    = var.django_secret_key
  django_allowed_hosts = var.django_allowed_hosts

  depends_on = [module.eks]
}
