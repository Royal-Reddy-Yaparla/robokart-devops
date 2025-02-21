output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}