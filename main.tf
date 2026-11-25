terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }
  required_version = ">= 1.5" # startswith() in modules/ec2 validation
}

provider "aws" {
  region                      = var.aws_region
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true

  default_tags {
    tags = {
      Project   = "school-wordpress"
      ManagedBy = "terraform"
    }
  }
}


module "vpc" {
  source   = "./modules/vpc"
  vpc_cidr = var.vpc_cidr
  azs      = var.azs
}

module "rds" {
  source                = "./modules/rds"
  vpc_id                = module.vpc.vpc_id
  subnet_ids            = module.vpc.private_db_subnet_ids
  ec2_security_group_id = module.ec2.ec2_sg_id
  db_name               = var.db_name
  db_username           = var.db_username
  db_instance_class     = var.db_instance_class
  multi_az              = var.multi_az
}

module "iam" {
  source        = "./modules/iam"
  db_secret_arn = module.rds.db_secret_arn
}

module "alb" {
  source          = "./modules/alb"
  vpc_id          = module.vpc.vpc_id
  vpc_cidr        = module.vpc.vpc_cidr
  subnet_ids      = module.vpc.public_subnet_ids
  certificate_arn = var.alb_certificate_arn
}

module "ec2" {
  source               = "./modules/ec2"
  image_id             = var.image_id
  instance_type        = var.instance_type
  vpc_id               = module.vpc.vpc_id
  vpc_cidr             = module.vpc.vpc_cidr
  subnet_ids           = module.vpc.private_app_subnet_ids
  sg_alb_id            = module.alb.alb_sg_id
  target_group_arn     = module.alb.target_group_arn
  iam_instance_profile = module.iam.instance_profile_name
  db_name              = module.rds.rds_database_name
  db_host              = module.rds.db_address
  db_secret_arn        = module.rds.db_secret_arn
}

module "cloudfront" {
  source          = "./modules/cloudfront"
  alb_dns_name    = module.alb.alb_dns_name
  domain_name     = var.domain_name
  certificate_arn = var.cloudfront_certificate_arn
}
