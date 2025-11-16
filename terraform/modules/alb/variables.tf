variable "project" {
  type        = string
  description = "Project identifier."
}

variable "env" {
  type        = string
  description = "Environment identifier."
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnets in which to place the load balancer."
}

variable "lb_security_group_id" {
  type        = string
  description = "Security group that controls LB ingress."
}

variable "vpc_id" {
  type        = string
  description = "VPC containing the target group."
}
