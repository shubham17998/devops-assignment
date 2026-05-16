variable "vpc_id" {
  description = "ID of the VPC to create subnets in"
  type        = string
}

variable "name_prefix" {
  description = "Prefix used for naming all subnet resources"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name for subnet discovery tags"
  type        = string
}

variable "internet_gateway_id" {
  description = "ID of the Internet Gateway (used for public routes and NAT EIP dependency)"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets (one per AZ)"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets (one per AZ)"
  type        = list(string)
}

variable "availability_zones" {
  description = "Explicit list of AZs to use. If empty, auto-selects based on az_count"
  type        = list(string)
  default     = []
}

variable "az_count" {
  description = "Number of AZs to use when availability_zones is not set"
  type        = number
  default     = 3
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}
