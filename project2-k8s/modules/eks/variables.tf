variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.29"
}

variable "private_subnet_ids" {
  description = "Private subnet IDs where worker nodes will be placed"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Public subnet IDs (for ALB and control plane cross-AZ traffic)"
  type        = list(string)
}

variable "cluster_security_group_id" {
  description = "Security group for EKS control plane"
  type        = string
}

variable "node_security_group_id" {
  description = "Security group for EKS worker nodes"
  type        = string
}

variable "cluster_endpoint_public_access" {
  description = "Whether the EKS API server is publicly accessible"
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "CIDRs allowed to access the public EKS endpoint (restrict to your office/VPN IP)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "node_instance_types" {
  description = "EC2 instance types for worker nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_capacity_type" {
  description = "Capacity type: ON_DEMAND or SPOT"
  type        = string
  default     = "ON_DEMAND"
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 5
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
