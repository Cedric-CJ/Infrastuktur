#!/usr/bin/env bash
# Deploy to dev environment

set -e

echo "🚀 Deploying to DEV environment..."

# Install dependencies first
./scripts/install-deps.sh

# Navigate to dev environment
cd terraform/envs/dev

# Initialize Terraform (if needed)
terraform init

# Format check
terraform fmt -check || terraform fmt

# Validate
terraform validate

# Plan
terraform plan -out=tfplan

# Apply
echo ""
echo "🔍 Review the plan above. Press Enter to apply or Ctrl+C to cancel..."
read

terraform apply tfplan

# Show outputs
echo ""
echo "📋 Deployment outputs:"
terraform output

echo ""
echo "✅ Deployment complete!"
