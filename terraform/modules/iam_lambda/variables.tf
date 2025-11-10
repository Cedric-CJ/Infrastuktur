variable "project" {
  type        = string
  description = "Project prefix"
}

variable "env" {
  type        = string
  description = "Environment name"
}

variable "comments_table_arn" {
  type        = string
  description = "Comments table ARN"
}

variable "reactions_table_arn" {
  type        = string
  description = "Reactions table ARN"
}

variable "logs_table_arn" {
  type        = string
  description = "Logs table ARN"
}

variable "users_table_arn" {
  type        = string
  description = "Users table ARN"
}
