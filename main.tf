provider "aws" {
  region  = var.main_aws_region
  profile = "ns"

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

  node_group_name     = var.eks_node_group_name
  node_instance_types = var.eks_node_instance_types
  node_desired_size   = var.eks_node_desired_size
  node_min_size       = var.eks_node_min_size
  node_max_size       = var.eks_node_max_size
  node_disk_size      = var.eks_node_disk_size
}
