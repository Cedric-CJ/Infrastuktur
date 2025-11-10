#!/usr/bin/env bash
# Show deployment information and next steps

set -e

cd terraform/envs/dev

if [ ! -f .terraform/terraform.tfstate ]; then
  echo "⚠️  Terraform not initialized yet"
  echo "   Run: make init-dev"
  exit 1
fi

echo "📋 Streamflix Deployment Info"
echo "=============================="
echo ""

if terraform output -json &>/dev/null; then
  API_URL=$(terraform output -raw api_base_url 2>/dev/null || echo "Not deployed yet")
  WEBSITE=$(terraform output -raw website_endpoint 2>/dev/null || echo "Not deployed yet")
  BUCKET=$(terraform output -raw video_bucket 2>/dev/null || echo "Not deployed yet")
  
  echo "🌐 API Gateway:"
  echo "   $API_URL"
  echo ""
  echo "🌐 Website:"
  echo "   http://$WEBSITE"
  echo ""
  echo "📦 S3 Bucket:"
  echo "   $BUCKET"
  echo ""
  
  if [ "$BUCKET" != "Not deployed yet" ]; then
    echo "📤 Upload frontend:"
    echo "   aws s3 sync frontend/ s3://$BUCKET/ --exclude '*.md'"
    echo ""
    echo "📤 Upload video:"
    echo "   aws s3 cp your-video.mp4 s3://$BUCKET/demo-video.mp4"
    echo ""
    echo "🔧 Update frontend/app.js:"
    echo "   const API = \"$API_URL\";"
    echo ""
    echo "🔧 Update frontend/index.html:"
    echo "   <video src=\"http://$WEBSITE/demo-video.mp4\">"
    echo ""
  fi
else
  echo "⚠️  Not deployed yet"
  echo ""
  echo "Run: make deploy-dev"
  echo ""
fi

echo "=============================="
echo "📚 Documentation:"
echo "   - README.md - Project overview"
echo "   - DEPLOY.md - Deployment guide"
echo "   - QUICKSTART.md - Quick reference"
echo ""
echo "💡 Commands:"
echo "   make help - Show all available commands"
