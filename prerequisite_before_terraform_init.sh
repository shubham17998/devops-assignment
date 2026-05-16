#!/usr/bin/env bash

set -euo pipefail

REGION="${1:-ap-south-1}"
BUCKET_NAME="${2:-my-terraform-state}"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "==> Creating Terraform state backend"
echo "    Region:    ${REGION}"
echo "    Bucket:    ${BUCKET_NAME}"
echo "    Account:   ${ACCOUNT_ID}"
echo ""

# --- S3 Bucket ---
if aws s3api head-bucket --bucket "${BUCKET_NAME}" 2>/dev/null; then
  echo "[SKIP] S3 bucket already exists: ${BUCKET_NAME}"
else
  echo "[CREATE] S3 bucket: ${BUCKET_NAME}"
  
  if [ "${REGION}" = "us-east-1" ]; then
    aws s3api create-bucket \
      --bucket "${BUCKET_NAME}" \
      --region "${REGION}"
  else
    aws s3api create-bucket \
      --bucket "${BUCKET_NAME}" \
      --region "${REGION}" \
      --create-bucket-configuration LocationConstraint="${REGION}"
  fi
fi

# Enable versioning
echo "[CONFIG] Enabling S3 versioning"
aws s3api put-bucket-versioning \
  --bucket "${BUCKET_NAME}" \
  --versioning-configuration Status=Enabled

# Enable server-side encryption
echo "[CONFIG] Enabling S3 server-side encryption (AES256)"
aws s3api put-bucket-encryption \
  --bucket "${BUCKET_NAME}" \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Block all public access
echo "[CONFIG] Blocking S3 public access"
aws s3api put-public-access-block \
  --bucket "${BUCKET_NAME}" \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

echo ""
echo "Backend bootstrap complete!"
echo ""
echo "Next steps:"
echo "  1. Update backend config in Terraform:"
echo "  2. terraform init"
echo "  3. terraform apply"
