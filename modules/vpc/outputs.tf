output "vpc_id" {
  description = "For alb, ec2, rds"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "For ec2 (MySQL egress) and the ALB egress rule"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "For alb subnet_ids"
  value       = aws_subnet.public[*].id
}

output "private_app_subnet_ids" {
  description = "For ec2 subnet_ids"
  value       = aws_subnet.private_app[*].id
}

output "private_db_subnet_ids" {
  description = "For rds subnet_ids"
  value       = aws_subnet.private_db[*].id
}
