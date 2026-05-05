# --------------------------------------------------------------------------------------------------
# This module creates Amazon ECR (Elastic Container Registry) repo to store Docker images for the application.
# --------------------------------------------------------------------------------------------------

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}


resource "aws_ecr_repository" "main" {
  name                 = var.name
  image_tag_mutability = var.image_tag_mutability
  force_delete         = var.force_delete

  # Configure automatic image scanning for vulnerabilities on each push
  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  # Encrypt images in the repository using the specified encryption type
  encryption_configuration {
    encryption_type = var.encryption_type
  }

  tags = {
    Name = var.name
  }
}

# --------------------------------------------------------------------------------------------------
# Lifecycle Policy for Docker images with automatic cleanup of old images
# --------------------------------------------------------------------------------------------------
resource "aws_ecr_lifecycle_policy" "main" {
  repository = aws_ecr_repository.main.name

  policy = jsonencode({
    rules = [
      {
        # Delete untagged images older than 14 days
        rulePriority = 1
        description  = "Delete untagged images older than 14 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 14
        }
        action = {
          type = "expire"
        }
      },
      {
        # Keep only the latest N images tagged by Jenkins (BUILD_NUMBER-SHA format)
        rulePriority = 2
        description  = "Keep only the latest ${var.max_image_count} tagged images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.max_image_count
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# --------------------------------------------------------------------------------------------------
# Repository Access Policy to allow full access for the current AWS account
# --------------------------------------------------------------------------------------------------
resource "aws_ecr_repository_policy" "main" {
  repository = aws_ecr_repository.main.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Allow full access to the current account for managing the repository and its images
        Sid    = "AllowCurrentAccountAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeRepositories",
          "ecr:GetRepositoryPolicy",
          "ecr:ListImages",
          "ecr:DeleteRepository",
          "ecr:BatchDeleteImage",
          "ecr:SetRepositoryPolicy",
          "ecr:DeleteRepositoryPolicy"
        ]
      }
    ]
  })
}
