output "alb_controller_role_arn" {
  description = "IAM role ARN for AWS Load Balancer Controller"
  value       = aws_iam_role.alb_controller.arn
}

output "external_secrets_role_arn" {
  description = "IAM role ARN for External Secrets Operator"
  value       = aws_iam_role.external_secrets.arn
}

output "cloudwatch_agent_role_arn" {
  description = "IAM role ARN for CloudWatch Agent"
  value       = aws_iam_role.cloudwatch_agent.arn
}
