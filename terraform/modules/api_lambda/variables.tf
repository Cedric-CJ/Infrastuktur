variable "project" {
  type        = string
  description = "Project prefix"
}

variable "env" {
  type        = string
  description = "Environment name"
}

variable "lambda_role_arn" {
  type        = string
  description = "IAM role assumed by Lambda functions"
}

variable "comments_table_name" {
  type        = string
  description = "Comments table name"
}

variable "reactions_table_name" {
  type        = string
  description = "Reactions table name"
}

variable "logs_table_name" {
  type        = string
  description = "Logs table name"
}

variable "users_table_name" {
  type        = string
  description = "Users table name"
}

variable "jwt_secret" {
  type        = string
  sensitive   = true
  description = "Secret used to sign JWTs"
}
