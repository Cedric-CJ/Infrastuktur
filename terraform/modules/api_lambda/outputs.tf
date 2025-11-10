output "api_base_url" {
  value       = aws_api_gateway_stage.this.invoke_url
  description = "Invoke URL for the deployed stage"
}
