variable "project" {
  type        = string
  description = "Project identifier."
}

variable "env" {
  type        = string
  description = "Environment identifier."
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where the security groups are created."
}

variable "admin_cidr" {
  type        = string
  description = "CIDR block that is allowed to SSH into the EC2 instances."
}
