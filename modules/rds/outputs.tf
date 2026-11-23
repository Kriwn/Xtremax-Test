output "db_address" {
  description = "RDS host name (no port), for the EC2 db_host input"
  value       = aws_db_instance.mysql_school.address
}

output "db_secret_arn" {
  description = "Secrets Manager ARN with the DB username and password"
  value       = aws_db_instance.mysql_school.master_user_secret[0].secret_arn
}

output "rds_sg_id" {
  value = aws_security_group.rds_sg.id
}

output "rds_port" {
  value = aws_db_instance.mysql.port
}

output "rds_database_name" {
  value = aws_db_instance.mysql.db_name
}
