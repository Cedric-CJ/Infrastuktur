#!/usr/bin/env bash
# Complete setup for Streamflix Infrastructure

set -e

echo "🎬 Streamflix Infrastructure Setup"
echo "=================================="
echo ""

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &>/dev/null; then
  echo "❌ AWS CLI not configured!"
  echo "   Run: aws configure"
  exit 1
fi

echo "✅ AWS CLI configured"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "   Account: $ACCOUNT_ID"
echo ""

# Check if JWT secret is set
if [ -z "$TF_VAR_jwt_secret" ]; then
  echo "⚠️  JWT Secret not set!"
  echo "   Generating one for you..."
  export TF_VAR_jwt_secret=$(openssl rand -base64 32)
  echo "   Generated: $TF_VAR_jwt_secret"
  echo ""
  echo "   💾 Save this to your .env file:"
  echo "   export TF_VAR_jwt_secret=\"$TF_VAR_jwt_secret\""
  echo ""
fi

# Step 1: Create backend
echo "📦 Step 1/4: Creating Remote State Backend..."
./scripts/create-backend.sh
echo ""

# Step 2: Install dependencies
echo "📦 Step 2/4: Installing Lambda Dependencies..."
./scripts/install-deps.sh
echo ""

# Step 3: Initialize Terraform
echo "🔧 Step 3/4: Initializing Terraform..."
cd terraform/envs/dev
terraform init
cd ../../..
echo ""

# Step 4: Validate
echo "✅ Step 4/4: Validating Configuration..."
cd terraform/envs/dev
terraform validate
cd ../../..
echo ""

echo "=================================="
echo "✅ Setup Complete!"
echo ""
echo "Next steps:"
echo "  1. Review the plan: make plan-dev"
echo "  2. Deploy: make deploy-dev"
echo ""
echo "📋 Quick commands:"
echo "  make help          - Show all available commands"
echo "  make outputs-dev   - Show deployment outputs"
echo "  make destroy-dev   - Destroy infrastructure"
