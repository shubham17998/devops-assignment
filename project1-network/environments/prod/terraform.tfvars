# Usage: terraform apply -var-file="environments/prod/terraform.tfvars"

aws_region   = "ap-south-1"
project_name = "devops-assignment"
environment  = "prod"
owner        = "platform-team"
cluster_name = "devops-assignment-prod"

vpc_cidr = "10.0.0.0/16"

# 3 public subnets for ALB and NAT Gateways
public_subnet_cidrs = [
  "10.0.1.0/24",
  "10.0.2.0/24",
  "10.0.3.0/24"
]

# 3 private subnets for EKS worker nodes
private_subnet_cidrs = [
  "10.0.11.0/24",
  "10.0.12.0/24",
  "10.0.13.0/24"
]

availability_zones = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
