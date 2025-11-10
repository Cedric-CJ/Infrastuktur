output "bucket_name" {
  value       = aws_s3_bucket.this.bucket
  description = "Generated bucket name"
}

output "website_endpoint" {
  value       = var.enable_website_host && length(aws_s3_bucket_website_configuration.this) > 0 ? aws_s3_bucket_website_configuration.this[0].website_endpoint : null
  description = "Public website endpoint when hosting is enabled"
}
