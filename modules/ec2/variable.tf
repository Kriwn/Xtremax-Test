variable "image_id" {
  description = "The AMI ID to use for the instance (null = latest Amazon Linux 2023)"
  type        = string
  default     = null
}

variable "instance_type" {
  description = "The type of instance to create"
  type        = string
  default     = "t2.micro"
}

variable "iam_instance_profile" {
  description = "IAM instance profile; its role needs AmazonSSMManagedInstanceCore and GetSecretValue on db_secret_arn"
  type        = string
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs for ASG"
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC"
}

variable "sg_alb_id" {
  type        = string
  description = "ALB security group ID (only source allowed on port 80)"
}

variable "target_group_arn" {
  type        = string
  description = "The ARN of the target group"
}

variable "db_name" {
  type        = string
  description = "WordPress database name"
}

variable "db_host" {
  type        = string
  description = "RDS endpoint address (without port)"
}

variable "db_secret_arn" {
  type        = string
  description = "Secrets Manager ARN holding the DB username and password"
}
