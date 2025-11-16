output "vpc_id" {
  value       = aws_vpc.this.id
  description = "ID of the created VPC."
}

output "public_subnet_ids" {
  value       = [for k in sort(keys(aws_subnet.public)) : aws_subnet.public[k].id]
  description = "IDs of the public subnets."
}

output "public_subnet_cidrs" {
  value       = [for k in sort(keys(aws_subnet.public)) : aws_subnet.public[k].cidr_block]
  description = "CIDR blocks used by the public subnets."
}
