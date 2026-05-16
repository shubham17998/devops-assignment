variable "vpc_id" {
  description = "VPC ID to create security groups in"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for all security group names"
  type        = string
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
