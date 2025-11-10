output "lambda_role_arn" {
  value       = aws_iam_role.lambda_exec.arn
  description = "Lambda execution role ARN"
}
