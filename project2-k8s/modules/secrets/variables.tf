variable "cluster_name" {
  type = string
}

variable "kms_key_arn" {
  description = "KMS key ARN for encrypting secrets"
  type        = string
}

variable "postgres_host" {
  description = "PostgreSQL host (RDS endpoint or in-cluster service name)"
  type        = string
  default     = "postgresql.keycloak.svc.cluster.local"
}

variable "tags" {
  type    = map(string)
  default = {}
}
