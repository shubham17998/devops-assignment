output "vpc_id" {
  description = "VPC ID consumed by Project 2 via remote state"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = module.vpc.vpc_cidr
}

output "public_subnet_ids" {
  description = "Public subnet IDs (for ALB, NAT GW placement)"
  value       = module.subnets.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs (for EKS worker nodes)"
  value       = module.subnets.private_subnet_ids
}

output "nat_public_ips" {
  description = "Elastic IPs of NAT Gateways (allowlist these on external services)"
  value       = module.subnets.nat_public_ips
}

output "availability_zones" {
  description = "AZs in use"
  value       = module.subnets.availability_zones
}

output "eks_cluster_sg_id" {
  description = "EKS control plane security group ID"
  value       = module.security_groups.eks_cluster_sg_id
}

output "eks_nodes_sg_id" {
  description = "EKS worker nodes security group ID"
  value       = module.security_groups.eks_nodes_sg_id
}
