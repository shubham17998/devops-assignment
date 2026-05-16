output "application_log_group" {
  value = aws_cloudwatch_log_group.application.name
}

output "performance_log_group" {
  value = aws_cloudwatch_log_group.performance.name
}
