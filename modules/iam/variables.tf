variable "db_secret_arn" {
  type        = string
  description = "The only secret the EC2 role may read (RDS master secret)"
}
