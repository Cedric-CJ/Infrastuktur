variable "project" {
  type        = string
  description = "Short project identifier used for names"
  default     = "streamflix"
}

variable "env" {
  type        = string
  description = "Environment descriptor (dev/prod)"
  default     = "dev"
}

variable "aws_region" {
  type        = string
  description = "AWS region for all resources"
  default     = "eu-central-1"
}

variable "jwt_secret" {
  type        = string
  sensitive   = true
  description = "HS256 secret for JWT issuance (use TF_VAR_jwt_secret env var)"
}
