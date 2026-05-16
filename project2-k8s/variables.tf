variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
  default     = "devops-assignment"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "owner" {
  description = "Owner tag"
  type        = string
  default     = "platform-team"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "devops-assignment-prod"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.29"
}

variable "node_instance_types" {
  description = "EC2 instance types for worker nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_capacity_type" {
  description = "ON_DEMAND or SPOT"
  type        = string
  default     = "ON_DEMAND"
}

variable "node_desired_size" {
  type    = number
  default = 2
}

variable "node_min_size" {
  type    = number
  default = 1
}

variable "node_max_size" {
  type    = number
  default = 5
}

variable "cluster_endpoint_public_access" {
  description = "Whether the EKS API endpoint is public"
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "CIDRs allowed to reach the public EKS endpoint (lock to your IP in production)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "keycloak_hostname" {
  description = "Hostname for Keycloak ingress (e.g. keycloak.prod.mosip.net)"
  type        = string
}

variable "keycloak_image_tag" {
  description = "Keycloak image tag"
  type        = string
  default     = "24.0.4"
}

variable "keycloak_replica_count" {
  description = "Number of Keycloak replicas"
  type        = number
  default     = 2
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for HTTPS on the ALB"
  type        = string
}
