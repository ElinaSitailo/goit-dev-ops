output "repository_url" {
  description = "URL of the ECR repository for pushing/pulling images"
  value       = aws_ecr_repository.main.repository_url
}

output "repository_arn" {
  description = "ARN of the ECR repository"
  value       = aws_ecr_repository.main.arn
}

output "registry_id" {
  description = "ID of the ECR registry (AWS account number)"
  value       = aws_ecr_repository.main.registry_id
}

output "repository_name" {
  description = "Name of the ECR repository"
  value       = aws_ecr_repository.main.name
}

output "docker_push_commands" {
  description = "Commands for pushing Docker images to the ECR repository"
  value = {
    login = "aws ecr get-login-password --region ${data.aws_region.current.name} | docker login --username AWS --password-stdin ${aws_ecr_repository.main.registry_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com"
    tag   = "docker tag my-image:latest ${aws_ecr_repository.main.repository_url}:latest"
    push  = "docker push ${aws_ecr_repository.main.repository_url}:latest"
  }
}
