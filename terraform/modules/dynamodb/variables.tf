variable "project" {
  type        = string
  description = "Project prefix"
}

variable "env" {
  type        = string
  description = "Environment name"
}

variable "ttl_enabled" {
  type        = bool
  description = "Enables TTL on logs table"
  default     = true
}
