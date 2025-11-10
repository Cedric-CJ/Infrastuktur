#!/usr/bin/env bash
# Create Terraform Remote State Backend (S3 + DynamoDB)

set -e

BUCKET_NAME="tf-state-streamflix-itinfra2025"
TABLE_NAME="tf-locks-streamflix"
REGION="eu-central-1"

echo "🔧 Creating Terraform Remote State Backend..."
echo ""
echo "Bucket: $BUCKET_NAME"
echo "Table:  $TABLE_NAME"
echo "Region: $REGION"
echo ""

# Check if bucket exists
if aws s3 ls "s3://${BUCKET_NAME}" 2>/dev/null; then
  echo "✅ S3 Bucket already exists: $BUCKET_NAME"
else
  echo "📦 Creating S3 Bucket: $BUCKET_NAME"
  aws s3 mb "s3://${BUCKET_NAME}" --region "$REGION"
  
  echo "🔒 Enabling versioning..."
  aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled
  
  echo "🔐 Enabling encryption..."
  aws s3api put-bucket-encryption \
    --bucket "$BUCKET_NAME" \
    --server-side-encryption-configuration '{
      "Rules": [{
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "AES256"
        }
      }]
    }'
  
  echo "🚫 Blocking public access..."
  aws s3api put-public-access-block \
    --bucket "$BUCKET_NAME" \
    --public-access-block-configuration \
      "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
  
  echo "✅ S3 Bucket created: $BUCKET_NAME"
fi

# Check if DynamoDB table exists
if aws dynamodb describe-table --table-name "$TABLE_NAME" --region "$REGION" 2>/dev/null; then
  echo "✅ DynamoDB Table already exists: $TABLE_NAME"
else
  echo "🗃️  Creating DynamoDB Table: $TABLE_NAME"
  aws dynamodb create-table \
    --table-name "$TABLE_NAME" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "$REGION"
  
  echo "⏳ Waiting for table to be active..."
  aws dynamodb wait table-exists --table-name "$TABLE_NAME" --region "$REGION"
  
  echo "✅ DynamoDB Table created: $TABLE_NAME"
fi

echo ""
echo "✅ Remote State Backend is ready!"
echo ""
echo "Next steps:"
echo "  1. Set JWT secret: export TF_VAR_jwt_secret=\$(openssl rand -base64 32)"
echo "  2. Deploy: make deploy-dev"
