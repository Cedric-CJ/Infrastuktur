variable "project" {
  type        = string
  description = "Short project identifier used for names"
  default     = "streamflix"
}

variable "env" {
  type        = string
  description = "Environment descriptor (dev/prod)"
  default     = "dev"
}

variable "aws_region" {
  type        = string
  description = "AWS region for all resources"
  default     = "eu-central-1"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR range for the VPC"
  default     = "10.21.0.0/16"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDRs for the public subnets used by ALB and ASG"
  default     = ["10.21.0.0/20", "10.21.16.0/20"]
}

variable "availability_zones" {
  type        = list(string)
  description = "AZs to distribute subnets to for HA"
  default     = ["eu-central-1a", "eu-central-1b"]
}

variable "admin_cidr" {
  type        = string
  description = "CIDR allowed to SSH into EC2 instances"
  default     = "0.0.0.0/0"
}

variable "instance_type" {
  type        = string
  description = "Instance type for Auto Scaling nodes"
  default     = "t3.micro"
}

variable "instance_key_name" {
  type        = string
  description = "Optional EC2 key pair for SSH"
  default     = null
}

variable "desired_capacity" {
  type        = number
  description = "Desired number of EC2 instances"
  default     = 2
}

variable "min_size" {
  type        = number
  description = "Minimum number of EC2 instances"
  default     = 2
}

variable "max_size" {
  type        = number
  description = "Maximum number of EC2 instances"
  default     = 4
}

variable "jwt_secret" {
  type        = string
  sensitive   = true
  description = "HS256 secret for JWT issuance (use TF_VAR_jwt_secret env var)"
}

variable "video_object_key" {
  type        = string
  description = "Object key inside the static bucket that stores the demo video"
  default     = "demo-video.mp4"
}
