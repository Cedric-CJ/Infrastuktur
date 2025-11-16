output "autoscaling_group_name" {
  value       = aws_autoscaling_group.this.name
  description = "Name of the Auto Scaling group."
}

output "launch_template_id" {
  value       = aws_launch_template.this.id
  description = "ID of the launch template powering the group."
}

output "instance_profile_name" {
  value       = aws_iam_instance_profile.this.name
  description = "Instance profile attached to the EC2 instances."
}
