# DevOps Assignment — AWS EKS + Keycloak

> Terraform/OpenTofu projects provisioning a production-ready network and Kubernetes platform on AWS, with Keycloak deployed via a custom Helm chart.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         AWS Account                             │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    VPC (10.0.0.0/16)                     │  │
│  │                                                          │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │  │
│  │  │ Public AZ-a  │  │ Public AZ-b  │  │ Public AZ-c  │  │  │
│  │  │ 10.0.1.0/24  │  │ 10.0.2.0/24  │  │ 10.0.3.0/24  │  │  │
│  │  │  [NAT GW]    │  │  [NAT GW]    │  │  [NAT GW]    │  │  │
│  │  │  [ALB]       │  │  [ALB]       │  │  [ALB]       │  │  │
│  │  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  │  │
│  │         │                 │                  │           │  │
│  │  ┌──────▼───────┐  ┌──────▼───────┐  ┌──────▼───────┐  │  │
│  │  │ Private AZ-a │  │ Private AZ-b │  │ Private AZ-c │  │  │
│  │  │ 10.0.11.0/24 │  │ 10.0.12.0/24 │  │ 10.0.13.0/24 │  │  │
│  │  │ [EKS Nodes]  │  │ [EKS Nodes]  │  │ [EKS Nodes]  │  │  │
│  │  └──────────────┘  └──────────────┘  └──────────────┘  │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────┐  ┌─────────────────┐  ┌───────────────────────┐  │
│  │   EKS    │  │ Secrets Manager │  │    CloudWatch Logs    │  │
│  │ Control  │  │ (Keycloak creds │  │ (Container Insights + │  │
│  │  Plane   │  │  + DB creds)    │  │    Fluent Bit)        │  │
│  └──────────┘  └─────────────────┘  └───────────────────────┘  │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                  EKS Cluster (keycloak ns)              │   │
│  │                                                         │   │
│  │   Internet → ALB → Keycloak Service → [blue|green]      │   │
│  │                                    ↓                    │   │
│  │                             PostgreSQL (StatefulSet)     │   │
│  │                                    ↓                    │   │
│  │                    External Secrets ← Secrets Manager    │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
---

## Design Decisions

### 1. Two Separate Terraform Projects with Remote State

Projects 1 and 2 are deliberately separate, each with their own S3-backed state file. Project 2 reads Project 1 outputs using `terraform_remote_state`. This allows:
- Independent lifecycle management (network rarely changes; workloads change often)
- Clear blast radius separation
- Team ownership boundaries

### 2. EKS Managed Node Groups over Self-Managed

AWS-managed node groups handle AMI updates, node drains, and replacement automatically. Combined with the EBS-encrypted launch template and IMDSv2 enforcement, this gives a secure, low-maintenance worker fleet.

### 3. IRSA Instead of Node-Level IAM

Every component that needs AWS API access (ALB controller, External Secrets, CloudWatch Agent) gets a dedicated IAM role bound to its Kubernetes service account via OIDC. This follows least-privilege: a pod cannot use another pod's AWS identity.

### 4. AWS Secrets Manager + External Secrets Operator

Secrets never appear in Helm values or Terraform state output (they are marked `sensitive = true`). External Secrets Operator pulls them at pod startup and refreshes every hour. This enables secret rotation without redeployment.

### 5. Blue-Green via Kubernetes Slot Labels

Each Helm release gets a `slot: blue` or `slot: green` label on its pods. The Service selector targets one slot. Switching traffic is a single `helm upgrade --set slot=green` with zero downtime and instant rollback capability (flip back to `slot: blue`).

### 6. PostgreSQL as StatefulSet (not RDS)

For this assignment, PostgreSQL runs in-cluster as a StatefulSet with a gp3 PVC. This keeps the project self-contained and cost-free to demo.

**In production:** Replace with Amazon RDS for PostgreSQL (Multi-AZ) for managed failover, automated backups, and performance insights.

### 7. gp3 StorageClass

gp3 provides 20% more IOPS than gp2 at the same price, with independently configurable IOPS and throughput. It is set as the cluster default with `Retain` reclaim policy to prevent accidental data loss.

### 8. NAT Gateway Per AZ

One NAT Gateway per availability zone ensures that private workloads survive an AZ failure without losing outbound internet access. This is more expensive than a single NAT GW but is the correct choice for production.

---

## Assumptions

1. **AWS credentials** are configured locally (`aws configure` or environment variables).
2. **Route53 hosted zone** exists for the Keycloak hostname (e.g. `example.com`).
3. **ACM certificate** for the Keycloak hostname already exists in the same region.
4. **Terraform >= 1.6** and **kubectl** and **Helm >= 3.12** are installed locally.
5. **AWS CLI v2** is installed (used by the EKS kubeconfig exec plugin).
6. The S3 bucket name in `main.tf` backend blocks is updated before `terraform init`.
7. For production, `public_access_cidrs` should be restricted to your VPN/office IP.

---

## Prerequisites

```bash
# Required tools
terraform version  # >= 1.6.0
aws --version      # >= 2.0
kubectl version    # >= 1.28
helm version       # >= 3.12
```

---

## Setup Instructions

### Step 0 — Bootstrap Terraform State Backend (once)

```bash
# Creates S3 bucket + DynamoDB table for remote state
./bootstrap-backend.sh ap-south-1
 my-terraform-state-bucket-sample1
```

Then update the `bucket` field in both `project1-network/main.tf` and `project2-k8s/main.tf`.

---

### Step 1 — Deploy Network (Project 1)

```bash
cd project1-network

terraform init

terraform plan \
  -var-file="environments/prod/terraform.tfvars" \
  -out=tfplan

terraform apply tfplan
```

Review the outputs — you'll see VPC ID, subnet IDs, and NAT Gateway IPs.

---

### Step 2 — Deploy Kubernetes & Services (Project 2)

```bash
cd project2-k8s

# Edit environments/prod/terraform.tfvars with your values:
#   keycloak_hostname  = "auth.yourdomain.com"
#   acm_certificate_arn = "arn:aws:acm:..."

terraform init

terraform plan \
  -var-file="environments/prod/terraform.tfvars" \
  -out=tfplan

terraform apply tfplan
```

This will:
1. Create the EKS cluster (~15 minutes)
2. Install ALB Controller, External Secrets Operator, CloudWatch Agent via Helm
3. Deploy Keycloak + PostgreSQL via the custom Helm chart

---

### Step 3 — Configure kubectl

```bash
aws eks update-kubeconfig \
  --region ap-south-1 \
  --name devops-assignment-prod
```

---

### Step 4 — Verify Deployment

```bash
# Check all pods are running
kubectl get pods -n keycloak
kubectl get pods -n external-secrets
kubectl get pods -n kube-system | grep aws-load-balancer

# Get the ALB DNS name
kubectl get ingress -n keycloak

# Check secrets were synced from Secrets Manager
kubectl get externalsecrets -n keycloak
kubectl get secrets -n keycloak
```

---

### Step 5 — Access Keycloak

Once the ALB is provisioned (2–3 minutes after apply):

```bash
# Get ALB URL
kubectl get ingress keycloak -n keycloak \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

Create a CNAME in Route53 pointing your hostname to this ALB DNS name. Then access:

```
https://auth.yourdomain.com/
https://auth.yourdomain.com/admin/  ← Admin console
```

Admin credentials are stored in AWS Secrets Manager under:
`<cluster-name>/keycloak/admin`

---

## Blue-Green Deployment

To deploy a new Keycloak version with zero downtime:

```bash
# Step 1: Deploy new version to "green" slot (inactive)
helm upgrade --install keycloak-green ./helm/keycloak \
  --namespace keycloak \
  --set slot=green \
  --set keycloak.image.tag=25.0.0   # New version

# Step 2: Verify green pods are healthy
kubectl rollout status deployment/keycloak-green -n keycloak
kubectl get pods -n keycloak -l slot=green

# Step 3: Switch traffic from blue → green
helm upgrade keycloak ./helm/keycloak \
  --namespace keycloak \
  --set slot=green   # Service now routes to green

# Step 4: Monitor for issues (watch logs, metrics)
kubectl logs -l slot=green -n keycloak --tail=100 -f

# Step 5a: All good — remove blue
helm uninstall keycloak-blue -n keycloak

# Step 5b: Problem — instant rollback
helm upgrade keycloak ./helm/keycloak \
  --namespace keycloak \
  --set slot=blue    # Instantly back to blue
```

---

## Observability

### Logs

All pod logs are shipped to CloudWatch via Fluent Bit:
- Log group: `/aws/eks/<cluster-name>/application`
- Log group: `/aws/eks/<cluster-name>/dataplane`

```bash
# View Keycloak logs in CloudWatch
aws logs tail /aws/eks/devops-assignment-prod/application \
  --filter-pattern "keycloak" \
  --follow
```

### Metrics

CloudWatch Container Insights provides:
- Node CPU/memory/disk utilization
- Pod CPU/memory requests vs limits
- Cluster-level aggregates

Access via: **CloudWatch Console → Container Insights → devops-assignment-prod**

### Alarms

Two CloudWatch alarms are created automatically:
- `devops-assignment-prod-node-cpu-high` — fires when CPU > 80% for 10 minutes
- `devops-assignment-prod-node-memory-high` — fires when memory > 80%

---

## Secrets Management

Secrets are never in Git, Helm values, or plain Terraform outputs.

| Secret | Secrets Manager Path | Rotation |
|--------|---------------------|----------|
| Keycloak admin creds | `<cluster>/keycloak/admin` | Manual |
| PostgreSQL root | `<cluster>/postgres/root` | Manual |
| Keycloak DB user | `<cluster>/postgres/keycloak` | Manual |

All secrets are encrypted with the cluster KMS key and have a 7-day recovery window.

To retrieve the Keycloak admin password:
```bash
aws secretsmanager get-secret-value \
  --secret-id devops-assignment-prod/keycloak/admin \
  --query SecretString \
  --output text | jq -r .password
```

---

## Cleanup

**Important:** Always destroy Project 2 before Project 1. Network resources cannot be deleted while cluster resources depend on them.

```bash
# Step 1: Destroy Kubernetes workloads (Project 2)
cd project2-k8s
terraform destroy \
  -var-file="environments/prod/terraform.tfvars" \
  -auto-approve

# Step 2: Destroy network (Project 1)
cd ../project1-network
terraform destroy \
  -var-file="environments/prod/terraform.tfvars" \
  -auto-approve

# Step 3: Optionally delete the state backend (manual)
aws s3 rb s3://my-terraform-state-bucket-sample1 --force
aws dynamodb delete-table --table-name terraform-state-locks
```
