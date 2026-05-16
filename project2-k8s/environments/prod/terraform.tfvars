aws_region   = "ap-south-1"
project_name = "devops-assignment"
environment  = "prod"
owner        = "platform-team"
cluster_name = "devops-assignment-prod"

kubernetes_version = "1.29"

node_instance_types = ["t3.medium"]
node_capacity_type  = "ON_DEMAND"
node_desired_size   = 2
node_min_size       = 1
node_max_size       = 5

# Lock this to your office/VPN IP in production!
cluster_endpoint_public_access = true
public_access_cidrs            = ["<ip>/32"]

keycloak_hostname      = "keycloak.prod.mosip.net"
keycloak_image_tag     = "24.0.4"
keycloak_replica_count = 2

acm_certificate_arn = "arn:aws:acm:us-east-1:ACCOUNT_ID:certificate/CERT_ID"  # <acm cert arn>
