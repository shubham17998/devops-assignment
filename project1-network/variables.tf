variable "aws_region" {
  description = "AWS region to deploy resources in"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name used in resource naming and tagging"
  type        = string
  default     = "devops-assignment"
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "owner" {
  description = "Owner tag for all resources"
  type        = string
  default     = "platform-team"
}

variable "cluster_name" {
  description = "EKS cluster name used for subnet discovery tags"
  type        = string
  default     = "devops-assignment-prod"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}

variable "availability_zones" {
  description = "Explicit AZ list. Leave empty to auto-select based on az_count"
  type        = list(string)
  default     = []
}

variable "az_count" {
  description = "Number of AZs when availability_zones is not provided"
  type        = number
  default     = 3
}
