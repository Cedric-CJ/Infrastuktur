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
  description = "Subnets used by the Auto Scaling Group."
}

variable "app_security_group_ids" {
  type        = list(string)
  description = "Security groups to attach to the EC2 instances."
}

variable "alb_target_group_arn" {
  type        = string
  description = "Target group ARN for load balancer registration."
}

variable "instance_type" {
  type        = string
  description = "Instance type for application servers."
  default     = "t3.micro"
}

variable "desired_capacity" {
  type        = number
  description = "Desired instance count."
  default     = 2
}

variable "min_size" {
  type        = number
  description = "Minimum instance count."
  default     = 2
}

variable "max_size" {
  type        = number
  description = "Maximum instance count."
  default     = 4
}

variable "frontend_bucket" {
  type        = string
  description = "S3 bucket that stores the latest frontend build."
}

variable "api_url" {
  type        = string
  description = "API Gateway URL used by the frontend."
}

variable "video_url" {
  type        = string
  description = "URL of the demo video served in the player."
}

variable "key_name" {
  type        = string
  description = "Optional EC2 key pair for SSH access."
  default     = null
}
