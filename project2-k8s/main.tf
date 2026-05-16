# Project 2 – Kubernetes & Services
# Provisions EKS cluster, deploys Keycloak + PostgreSQL via Helm,
# configures secrets management, ingress, blue-green, and observability

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.27"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  backend "s3" {
    bucket       = "my-terraform-state-sample1"
    key          = "terraform.tfstate"
    region       = "ap-south-1"
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

# Read network outputs from Project 1 remote state

data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "my-terraform-state-bucket-sample1"  # Replace with your bucket
    key    = "network/terraform.tfstate"
    region = var.aws_region
  }
}

data "aws_caller_identity" "current" {}

locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = var.owner
  }

  # Network values from Project 1
  vpc_id             = data.terraform_remote_state.network.outputs.vpc_id
  private_subnet_ids = data.terraform_remote_state.network.outputs.private_subnet_ids
  public_subnet_ids  = data.terraform_remote_state.network.outputs.public_subnet_ids
  cluster_sg_id      = data.terraform_remote_state.network.outputs.eks_cluster_sg_id
  node_sg_id         = data.terraform_remote_state.network.outputs.eks_nodes_sg_id
}

# Kubernetes and Helm providers (after cluster is created)

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
    }
  }
}

# EKS Cluster

module "eks" {
  source = "./modules/eks"

  cluster_name              = var.cluster_name
  kubernetes_version        = var.kubernetes_version
  private_subnet_ids        = local.private_subnet_ids
  public_subnet_ids         = local.public_subnet_ids
  cluster_security_group_id = local.cluster_sg_id
  node_security_group_id    = local.node_sg_id
  node_instance_types       = var.node_instance_types
  node_capacity_type        = var.node_capacity_type
  node_desired_size         = var.node_desired_size
  node_min_size             = var.node_min_size
  node_max_size             = var.node_max_size
  cluster_endpoint_public_access = var.cluster_endpoint_public_access
  public_access_cidrs       = var.public_access_cidrs
  tags                      = local.common_tags
}

# IAM Roles for Service Accounts

module "irsa" {
  source = "./modules/irsa"

  cluster_name      = var.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.cluster_oidc_issuer_url
  aws_region        = var.aws_region
  account_id        = data.aws_caller_identity.current.account_id
  tags              = local.common_tags
}

# Secrets Manager

module "secrets" {
  source = "./modules/secrets"

  cluster_name = var.cluster_name
  kms_key_arn  = module.eks.kms_key_arn
  tags         = local.common_tags
}

# CloudWatch

module "observability" {
  source = "./modules/observability"

  cluster_name = var.cluster_name
  aws_region   = var.aws_region
  tags         = local.common_tags
}

# Kubernetes Namespaces

resource "kubernetes_namespace" "keycloak" {
  metadata {
    name = "keycloak"
    labels = {
      "app.kubernetes.io/managed-by" = "Terraform"
    }
  }
  depends_on = [module.eks]
}

resource "kubernetes_namespace" "external_secrets" {
  metadata {
    name = "external-secrets"
  }
  depends_on = [module.eks]
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "amazon-cloudwatch"
  }
  depends_on = [module.eks]
}

# AWS Load Balancer Controller

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.7.2"

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.irsa.alb_controller_role_arn
  }

  set {
    name  = "vpcId"
    value = local.vpc_id
  }

  set {
    name  = "region"
    value = var.aws_region
  }

  depends_on = [module.eks, module.irsa]
}

# External Secrets Operator

resource "helm_release" "external_secrets" {
  name       = "external-secrets"
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  namespace  = kubernetes_namespace.external_secrets.metadata[0].name
  version    = "0.9.13"

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.irsa.external_secrets_role_arn
  }

  depends_on = [kubernetes_namespace.external_secrets, module.irsa]
}

# Keycloak 

resource "helm_release" "keycloak" {
  name      = "keycloak"
  chart     = "${path.module}/../../helm/keycloak"
  namespace = kubernetes_namespace.keycloak.metadata[0].name

  values = [
    templatefile("${path.module}/../../helm/keycloak/values.yaml", {
      aws_region        = var.aws_region
      cluster_name      = var.cluster_name
      keycloak_hostname = var.keycloak_hostname
    })
  ]

  set {
    name  = "keycloak.image.tag"
    value = var.keycloak_image_tag
  }

  set {
    name  = "keycloak.replicaCount"
    value = var.keycloak_replica_count
  }

  set {
    name  = "ingress.hostname"
    value = var.keycloak_hostname
  }

  set {
    name  = "ingress.certificateArn"
    value = var.acm_certificate_arn
  }

  timeout = 600

  depends_on = [
    helm_release.aws_load_balancer_controller,
    helm_release.external_secrets,
    kubernetes_namespace.keycloak
  ]
}

# CloudWatch Insights

resource "helm_release" "cloudwatch_agent" {
  name       = "amazon-cloudwatch-observability"
  repository = "https://aws.github.io/eks-charts"
  chart      = "amazon-cloudwatch-observability"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  version    = "1.5.2"

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "region"
    value = var.aws_region
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.irsa.cloudwatch_agent_role_arn
  }

  depends_on = [module.eks, kubernetes_namespace.monitoring]
}
