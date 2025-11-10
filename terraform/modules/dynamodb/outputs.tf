output "users_table_name" {
  value       = aws_dynamodb_table.users.name
  description = "Users table name"
}

output "comments_table_name" {
  value       = aws_dynamodb_table.comments.name
  description = "Comments table name"
}

output "reactions_table_name" {
  value       = aws_dynamodb_table.reactions.name
  description = "Reactions table name"
}

output "logs_table_name" {
  value       = aws_dynamodb_table.logs.name
  description = "Logs table name"
}

output "users_table_arn" {
  value       = aws_dynamodb_table.users.arn
  description = "Users table ARN"
}

output "comments_table_arn" {
  value       = aws_dynamodb_table.comments.arn
  description = "Comments table ARN"
}

output "reactions_table_arn" {
  value       = aws_dynamodb_table.reactions.arn
  description = "Reactions table ARN"
}

output "logs_table_arn" {
  value       = aws_dynamodb_table.logs.arn
  description = "Logs table ARN"
}
