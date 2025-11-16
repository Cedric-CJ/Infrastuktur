variable "project" {
  type        = string
  description = "Project identifier used for tagging resources."
}

variable "env" {
  type        = string
  description = "Environment identifier."
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC."
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "List of CIDR blocks for the public subnets."
}

variable "availability_zones" {
  type        = list(string)
  description = "List of AZs to spread the public subnets across."
}
