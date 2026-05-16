# Secrets Module

resource "random_password" "keycloak_admin" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_password" "postgres_password" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_password" "postgres_keycloak_password" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Keycloak Admin Secret

resource "aws_secretsmanager_secret" "keycloak_admin" {
  name                    = "${var.cluster_name}/keycloak/admin"
  description             = "Keycloak admin credentials"
  kms_key_id              = var.kms_key_arn
  recovery_window_in_days = 7

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "keycloak_admin" {
  secret_id = aws_secretsmanager_secret.keycloak_admin.id
  secret_string = jsonencode({
    username = "admin"
    password = random_password.keycloak_admin.result
  })
}

# PostgreSQL Root Secret

resource "aws_secretsmanager_secret" "postgres" {
  name                    = "${var.cluster_name}/postgres/root"
  description             = "PostgreSQL root credentials"
  kms_key_id              = var.kms_key_arn
  recovery_window_in_days = 7

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "postgres" {
  secret_id = aws_secretsmanager_secret.postgres.id
  secret_string = jsonencode({
    username = "postgres"
    password = random_password.postgres_password.result
    host     = var.postgres_host
    port     = "5432"
    dbname   = "postgres"
  })
}

# Keycloak DB User Secret

resource "aws_secretsmanager_secret" "keycloak_db" {
  name                    = "${var.cluster_name}/postgres/keycloak"
  description             = "PostgreSQL keycloak user credentials"
  kms_key_id              = var.kms_key_arn
  recovery_window_in_days = 7

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "keycloak_db" {
  secret_id = aws_secretsmanager_secret.keycloak_db.id
  secret_string = jsonencode({
    username = "keycloak"
    password = random_password.postgres_keycloak_password.result
    host     = var.postgres_host
    port     = "5432"
    dbname   = "keycloak"
  })
}
