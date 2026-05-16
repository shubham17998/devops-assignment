output "keycloak_admin_secret_arn" {
  description = "ARN of the Keycloak admin secret"
  value       = aws_secretsmanager_secret.keycloak_admin.arn
}

output "postgres_secret_arn" {
  description = "ARN of the PostgreSQL root secret"
  value       = aws_secretsmanager_secret.postgres.arn
}

output "keycloak_db_secret_arn" {
  description = "ARN of the Keycloak DB user secret"
  value       = aws_secretsmanager_secret.keycloak_db.arn
}

output "keycloak_admin_password" {
  description = "Generated Keycloak admin password (sensitive)"
  value       = random_password.keycloak_admin.result
  sensitive   = true
}
