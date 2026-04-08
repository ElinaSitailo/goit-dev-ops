variable "name" {
  description = "ECR repository name"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9/_.-]{1,253}[a-z0-9]$", var.name))
    error_message = "ECR repository name must contain only lowercase letters, numbers, and the characters /, _, ., -."
  }
}

variable "scan_on_push" {
  description = "Automatically scan images on push"
  type        = bool
}

variable "image_tag_mutability" {
  description = "Image tag mutability (MUTABLE or IMMUTABLE)"
  type        = string

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "Value must be MUTABLE or IMMUTABLE."
  }
}

variable "force_delete" {
  description = "Force delete the repository even if it contains images"
  type        = bool
}

variable "max_image_count" {
  description = "Maximum number of images in the repository"
  type        = number
}

variable "encryption_type" {
  description = "Encryption type (AES256 or KMS)"
  type        = string

  validation {
    condition     = contains(["AES256", "KMS"], var.encryption_type)
    error_message = "Encryption type must be AES256 or KMS."
  }
}
