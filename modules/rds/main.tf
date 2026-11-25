resource "aws_db_subnet_group" "school_db_subnet_group" {
  name       = "school-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "school-db-subnet-group"
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "rds-mysql-sg"
  description = "Allow MySQL from EC2 only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "MySQL from WordPress EC2"
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = [var.ec2_security_group_id]
  }

  # No egress block: Terraform removes the default allow-all, so RDS cannot connect out

  tags = {
    Name = "rds-mysql-sg"
  }
}

resource "aws_db_instance" "mysql_school" {
  identifier     = var.db_identifier
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.db_instance_class
  port           = var.db_port

  db_name  = var.db_name
  username = var.db_username
  # RDS creates the password and keeps it in Secrets Manager (never in tfvars or code)
  manage_master_user_password = true

  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  multi_az            = var.multi_az
  publicly_accessible = false
  skip_final_snapshot = true

  backup_retention_period = 7 # point-in-time restore to any second in the last 7 days

  db_subnet_group_name   = aws_db_subnet_group.school_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
}
