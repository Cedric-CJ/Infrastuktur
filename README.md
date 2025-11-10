# 🎬 Streamflix - AWS Streaming MVP Infrastructure

Minimal but realistic Terraform stack to host the streaming MVP described in the brief:

- **S3 static site** bucket for frontend assets and demo video.
- **API Gateway (REST)** fronting **Lambda** handlers for auth/comments/reactions.
- **DynamoDB** tables for users, comments, reactions, logs.
- **IAM** role + policy for the Lambdas.
- **GitHub Actions** workflow that runs init/fmt/validate/plan on every push/PR.

```
aws-streaming-mvp-iac/
|-- terraform/envs/{dev,prod}/
|-- terraform/modules/{s3_static_site,dynamodb,iam_lambda,api_lambda}/
|-- lambdas/{auth_signup,auth_login,comments_write,reactions_write}/
|-- frontend/{index.html,app.js,styles.css}
`-- .github/workflows/terraform.yml
```

## Prerequisites

- Terraform >= 1.6
- AWS credentials with permissions for S3, Lambda, API Gateway, DynamoDB, IAM
- Node.js 20.x locally for installing Lambda dependencies
- Optional: `zip`/`Compress-Archive` if you prefer manual packaging (Terraform already zips via `archive_file`)

## Getting started

### 1. Remote State Setup

Create the S3 bucket and DynamoDB table for Terraform state:

```bash
# Option A: Automated
make backend

# Option B: Manual
./scripts/create-backend.sh
```

This creates:
- S3 Bucket: `tf-state-streamflix-itinfra2025`
- DynamoDB Table: `tf-locks-streamflix`
- Region: `eu-central-1`

### 2. Set JWT Secret

```bash
# Generate a secure secret
export TF_VAR_jwt_secret=$(openssl rand -base64 32)

# Or set manually
export TF_VAR_jwt_secret="your-secure-secret-here"

# Optional: Save to .env file
echo "export TF_VAR_jwt_secret=\"$TF_VAR_jwt_secret\"" >> .env
```

### 3. Install Lambda Dependencies

```bash
make install-deps
```

### 4. Deploy Infrastructure

```bash
# Initialize Terraform
make init-dev

# Review the plan
make plan-dev

# Deploy
make deploy-dev

# Get outputs
make outputs-dev
```

### 5. Upload Frontend & Video

```bash
# Get bucket name from outputs
BUCKET=$(cd terraform/envs/dev && terraform output -raw video_bucket)

# Upload frontend files
aws s3 sync frontend/ s3://$BUCKET/ --exclude "*.md"

# Upload demo video
aws s3 cp path/to/your-video.mp4 s3://$BUCKET/demo-video.mp4
```

### 6. Configure Frontend URLs

Update `frontend/app.js` with your API URL:
```javascript
const API = "https://YOUR-API-ID.execute-api.eu-central-1.amazonaws.com/dev";
```

Update `frontend/index.html` with your video URL:
```html
<video src="http://YOUR-BUCKET.s3-website.eu-central-1.amazonaws.com/demo-video.mp4">
```

Get these URLs from terraform outputs:
```bash
make outputs-dev
```

## Quick Commands

```bash
make help           # Show all commands
make backend        # Create remote state backend
make install-deps   # Install Lambda dependencies
make deploy-dev     # Deploy dev environment
make outputs-dev    # Show deployment URLs
make destroy-dev    # Destroy infrastructure
```

## Configuration

### Project Settings
- **Project ID**: `streamflix`
- **Environments**: `dev`, `prod`
- **AWS Region**: `eu-central-1`
- **Remote State Bucket**: `tf-state-streamflix-itinfra2025`
- **Lock Table**: `tf-locks-streamflix`

### GitHub Actions Secrets

Required secrets for CI/CD:
```
AWS_ACCESS_KEY_ID        - Your AWS access key
AWS_SECRET_ACCESS_KEY    - Your AWS secret key
AWS_REGION               - eu-central-1
TF_VAR_jwt_secret        - JWT signing secret (optional)
```

## Prerequisites

- Terraform >= 1.6
- AWS credentials with permissions for S3, Lambda, API Gateway, DynamoDB, IAM
- Node.js 20.x locally for installing Lambda dependencies
- AWS CLI configured

## Getting started

1. **Remote state**  
   - Update `terraform/envs/*/backend.tf` with your state bucket and lock table.

2. **Variables**  
   - Adjust `project`, `env`, `aws_region`, `jwt_secret` in `terraform/envs/dev|prod/variables.tf`.

3. **Install Lambda deps**  
   ```bash
   cd lambdas/auth_signup && npm install --omit=dev
   cd ../auth_login && npm install --omit=dev
   cd ../comments_write && npm install --omit=dev
   cd ../reactions_write && npm install --omit=dev
   ```
   Terraform picks up the resulting `node_modules` and produces ZIPs automatically through `archive_file`.

4. **Provision**  
   ```bash
   cd terraform/envs/dev
   terraform init
   terraform plan
   terraform apply
   ```

5. **Record outputs**  
   - `api_base_url`
   - `website_endpoint`
   - `video_bucket`

6. **Upload assets**  
   - Push your demo video plus `frontend/*` into the emitted bucket.
   - Replace the placeholders in `frontend/index.html` and `frontend/app.js` with the real bucket/API URLs.

## Lambdas (Node.js)

- `auth_signup`: hashes passwords via `scrypt`, stores anonymised `email_hash`, `pwd_hash`, `salt`.
- `auth_login`: expects `user_id` (MVP simplification), validates credentials, issues HS256 JWT.
- `comments_write` / `reactions_write`: JWT verification, writes to DynamoDB, ships a lightweight log entry.

> Production hardening would add a DynamoDB GSI on `email_hash`, Secrets Manager/KMS for secrets, and CloudFront in front of S3.

## GitHub Actions

`.github/workflows/terraform.yml` runs on pushes to `main` and on PRs:

1. Checkout
2. Install Terraform 1.6.6
3. `terraform init`
4. `terraform fmt -check`
5. `terraform validate`
6. `terraform plan`

Provide `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION` as repository secrets.

## Deploy checklist

1. Configure AWS credentials locally or in GitHub Secrets.
2. Update `backend.tf` with your remote state location.
3. Run `npm install --omit=dev` inside each Lambda folder so Terraform can package dependencies.
4. `terraform -chdir=terraform/envs/dev apply`.
5. Note the outputs (`api_base_url`, `website_endpoint`, `video_bucket`).
6. Upload the frontend/video to S3, wire URLs into the frontend.
7. Smoke-test the flow:
   - Sign up -> capture returned `user_id`.
   - Login -> browser stores JWT in `localStorage`.
   - POST a comment (Authorization header `Bearer <token>`).

## Possible next steps

1. Add CloudFront + Route 53 in front of the static site.
2. Introduce a DynamoDB GSI on `email_hash` (login without user_id).
3. Manage JWT secrets in AWS Secrets Manager with rotation.
4. Add a presigned-upload workflow so creators can push their own videos.

Ping me with your preferred project/env identifiers if you want those defaults baked in.
