variable "bucket_name_prefix" {
  type        = string
  description = "Prefix used when generating the S3 bucket name"
}

variable "enable_website_host" {
  type        = bool
  description = "Whether to enable static website hosting"
  default     = true
}
