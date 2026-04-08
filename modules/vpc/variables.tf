variable "name" {
  description = "Name of the VPC"
  type        = string
  default     = "lesson-5-vpc"
}

variable "cidr_block" {
  description = "CIDR block for the VPC"
  type        = string

  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "You must specify a valid CIDR block."
  }
}

variable "public_subnets" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)

  validation {
    condition     = length(var.public_subnets) >= 1
    error_message = "You must specify at least one public subnet."
  }
}

variable "private_subnets" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)

  validation {
    condition     = length(var.private_subnets) >= 1
    error_message = "You must specify at least one private subnet."
  }
}

variable "availability_zones" {
  description = "List of availability zones for placing subnets"
  type        = list(string)
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC"
  type        = bool
}
