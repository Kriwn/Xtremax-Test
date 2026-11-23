#subnet
variable "subnet_ids" {
  type        = list(string)
  description = "List of private DB subnet IDs for the RDS (at least 2 AZs)"
}

# security group
variable "vpc_id" {
  type        = string
  description = "The ID of the VPC"
}

variable "db_port" {
  type        = number
  description = "The port for the database"
  default     = 3306
}

variable "ec2_security_group_id" {
  type        = string
  description = "The ID of the EC2 security group allowed to access RDS"
}

# db_instance

variable "db_identifier" {
  type        = string
  description = "The identifier for the RDS"
  default     = "mysql-school"
}

variable "db_name" {
  type        = string
  description = "The name of the database"
}

variable "db_username" {
  type        = string
  description = "The master username (the password is created by RDS in Secrets Manager)"
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "multi_az" {
  type        = bool
  description = "Standby copy in a second AZ; set true for production"
  default     = false
}
