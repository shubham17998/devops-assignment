# Project 1 – Network
# Provisions a production-ready VPC for EKS workloads
#
# Architecture:
#   - VPC with 3 public + 3 private subnets across 3 AZs
#   - Internet Gateway for public internet access
#   - NAT Gateway per AZ (HA) for private subnet outbound traffic
#   - VPC Flow Logs to CloudWatch for security auditing
#   - Security groups for EKS control plane and worker nodes
#   - S3 remote state backend with locking

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket       = "my-terraform-state-sample1"
    key          = "terraform.tfstate"
    region       = "ap-south-1"
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = var.owner
  }
}

# VPC

module "vpc" {
  source = "./modules/vpc"

  vpc_name     = "${var.project_name}-${var.environment}-vpc"
  vpc_cidr     = var.vpc_cidr
  cluster_name = var.cluster_name
  tags         = local.common_tags
}

# Subnets

module "subnets" {
  source = "./modules/subnets"

  vpc_id               = module.vpc.vpc_id
  name_prefix          = "${var.project_name}-${var.environment}"
  cluster_name         = var.cluster_name
  internet_gateway_id  = module.vpc.internet_gateway_id
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  az_count             = var.az_count
  tags                 = local.common_tags
}

# Security Groups

module "security_groups" {
  source = "./modules/security-groups"

  vpc_id      = module.vpc.vpc_id
  name_prefix = "${var.project_name}-${var.environment}"
  tags        = local.common_tags
}
