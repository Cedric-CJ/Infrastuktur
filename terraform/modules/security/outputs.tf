output "lb_security_group_id" {
  value       = aws_security_group.lb.id
  description = "Security group ID for the load balancer."
}

output "app_security_group_id" {
  value       = aws_security_group.app.id
  description = "Security group ID for the EC2 instances."
}
