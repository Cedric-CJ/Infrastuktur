#!/usr/bin/env bash
# Check AWS Free Tier usage and costs

echo "🔍 AWS FREE TIER STATUS CHECK"
echo "=============================="
echo ""

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &>/dev/null; then
  echo "❌ AWS CLI not configured!"
  echo "   Run: aws configure"
  echo "   Or see: AWS_FREE_SETUP.md"
  exit 1
fi

echo "✅ AWS CLI configured"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "   Account: $ACCOUNT_ID"
echo ""

echo "📊 FREE TIER LIMITS (EU-CENTRAL-1):"
echo "-----------------------------------"
echo "• S3:           5GB storage, 20K GET, 2K PUT requests"
echo "• Lambda:       1M requests, 400K GB-seconds"
echo "• API Gateway:  1M requests"
echo "• DynamoDB:     25GB storage, 200M requests"
echo "• CloudWatch:   5GB logs"
echo ""

echo "💰 CURRENT COSTS (last 30 days):"
echo "---------------------------------"

# Get current costs (requires Cost Explorer enabled)
COST_DATA=$(aws ce get-cost-and-usage \
  --time-period Start=$(date -d '30 days ago' +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE \
  2>/dev/null || echo "Cost Explorer not enabled")

if [ "$COST_DATA" != "Cost Explorer not enabled" ]; then
  echo "$COST_DATA" | jq -r '.ResultsByTime[0].Groups[] | select(.Metrics.BlendedCost.Amount != "0") | "• \(.Keys[0]): $\(.Metrics.BlendedCost.Amount)"' 2>/dev/null || echo "No costs found"
else
  echo "⚠️  Cost Explorer not enabled"
  echo "   Enable in: https://console.aws.amazon.com/billing/home#/costexplorer"
fi

echo ""
echo "🔧 SERVICES IN USE:"
echo "-------------------"

# Check S3 buckets
BUCKETS=$(aws s3 ls 2>/dev/null | wc -l)
echo "• S3 Buckets: $BUCKETS"

# Check Lambda functions
LAMBDAS=$(aws lambda list-functions --region eu-central-1 2>/dev/null | jq '.Functions | length' 2>/dev/null || echo "0")
echo "• Lambda Functions: $LAMBDAS"

# Check DynamoDB tables
TABLES=$(aws dynamodb list-tables --region eu-central-1 2>/dev/null | jq '.TableNames | length' 2>/dev/null || echo "0")
echo "• DynamoDB Tables: $TABLES"

# Check API Gateways
APIS=$(aws apigateway get-rest-apis --region eu-central-1 2>/dev/null | jq '.items | length' 2>/dev/null || echo "0")
echo "• API Gateways: $APIS"

echo ""
echo "💡 TIPS TO STAY FREE:"
echo "---------------------"
echo "• Keep videos < 5GB total"
echo "• Limit to < 1000 requests/day"
echo "• Delete resources when not testing"
echo "• Monitor billing daily"
echo ""
echo "🧹 CLEANUP COMMAND:"
echo "   make destroy-dev"