terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.14"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.36"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  required_version = ">= 1.2"

  backend "s3" {
    bucket = "ns-bucket-to-store-tf-state-devops-lesson-5-04082026"
    key    = "lesson-5/terraform.tfstate"
    region = "eu-north-1"
    # dynamodb_table = "terraform-state-locks-table" # The parameter "dynamodb_table" is deprecated. Use parameter "use_lockfile" instead.
    use_lockfile = true
    encrypt      = true
  }
}
