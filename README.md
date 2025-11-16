# 🎬 Streamflix - AWS Streaming MVP Infrastructure

Minimal but realistic Terraform stack to host the streaming MVP described in the brief:

- **S3 static site** bucket for frontend assets and demo video.
- **API Gateway (REST)** fronting **Lambda** handlers for auth/comments/reactions.
- **DynamoDB** tables for users, comments, reactions, logs.
- **IAM** role + policy for the Lambdas.
- **VPC + public subnets** including routing + security groups.
- **Application Load Balancer + Auto Scaling Group** that runs an Nginx based web tier and keeps it synced with the S3 assets every 5 minutes.
- **AWS CodeBuild/CodePipeline ready buildspec** that installs Terraform, runs `terraform apply`, and pushes the latest frontend bundle to S3 whenever AWS CodePipeline pulls from GitHub.

```
aws-streaming-mvp-iac/
|-- terraform/envs/{dev,prod}/
|-- terraform/modules/{s3_static_site,dynamodb,iam_lambda,api_lambda,networking,security,alb,autoscaling}/
|-- lambdas/{auth_signup,auth_login,comments_write,reactions_write}/
|-- frontend/{index.html,app.js,styles.css}
|-- buildspec.yml
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

The CodeBuild pipeline (see below) already runs `aws s3 sync frontend/ s3://<bucket>/ --delete` after every `terraform apply`.  
To test locally you can still push assets manually:

```bash
BUCKET=$(cd terraform/envs/dev && terraform output -raw video_bucket)
aws s3 sync frontend/ s3://$BUCKET/ --exclude "*.md" --delete
aws s3 cp demo-video.mp4 s3://$BUCKET/demo-video.mp4
```

### 6. Configure Frontend URLs (automatic)

The EC2 user data replaces `REPLACE_WITH_API_BASE_URL` and `REPLACE_WITH_S3_VIDEO_URL` with the Terraform outputs during every sync, so you no longer have to edit the files by hand.  
If you need the raw values:

```bash
cd terraform/envs/dev
terraform output api_base_url
terraform output video_bucket
terraform output load_balancer_dns
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

## Architecture Overview

- **Edge / Clients** – Users hit the Application Load Balancer DNS that Terraform outputs. Admins can still SSH (port 22) thanks to the `admin_cidr` variable.
- **Application tier** – An Auto Scaling Group (min 2 instances) launches Amazon Linux 2023, installs Nginx, and runs a systemd timer that syncs the latest frontend build from S3 every 5 minutes. Placeholders for API + video URLs are replaced during each sync.
- **API tier** – API Gateway exposes `/auth/*`, `/comments`, `/reactions` and invokes the Lambda functions stored under `lambdas/`.
- **State** – DynamoDB tables hold users, comments, reactions, and log entries. IAM policies restrict each Lambda to the tables it needs.
- **Static assets** – One S3 bucket stores `frontend/` plus your demo video. The EC2 tier serves the synced assets via the load balancer, but the bucket also exposes a website endpoint.

## AWS Pipeline (CodePipeline + CodeBuild)

The repository ships with `buildspec.yml` so the AWS side only wires services together:

1. **Create a CodeStar connection** to GitHub (Developer Tools → Connections) and authorize your repo/branch.
2. **Provision a CodeBuild project**:
   - Runtime: `aws/codebuild/standard:7.0` or newer so Node 20 is available.
   - Source: GitHub connection from step 1.
   - Environment variables:  
     `TF_VAR_jwt_secret` (secure, value from `openssl rand -base64 32`), `AWS_REGION=eu-central-1` if you deploy elsewhere.  
   - Service role needs: `AmazonS3FullAccess`, `AWSLambda_FullAccess`, `AmazonDynamoDBFullAccess`, `AmazonAPIGatewayAdministrator`, `AmazonEC2FullAccess`, `ElasticLoadBalancingFullAccess`, `AutoScalingFullAccess`, `CloudWatchLogsFullAccess`, plus `iam:PassRole` for the Lambda + EC2 instance profiles.
3. **Create a CodePipeline** with:
   - Source stage → GitHub (CodeStar connection).
   - Build stage → the CodeBuild project above. No Deploy stage is needed because Terraform + the `aws s3 sync` inside `buildspec.yml` already handle deployments.
4. Whenever CodePipeline runs, CodeBuild:
   - Installs Terraform 1.7.5 and Lambda `node_modules`.
   - Executes `terraform apply` in `terraform/envs/dev`.
   - Reads the outputs (`video_bucket`, `api_base_url`, `load_balancer_dns`) and syncs `frontend/` into the bucket so the EC2 sync timer can pick up the new build automatically.

> Tip: attach the same remote-state bucket/table credentials that you use locally so CodeBuild shares the state file.

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
   - `load_balancer_dns`
   - `autoscaling_group`

6. **Upload assets (optional)**  
   - The CodeBuild pipeline and EC2 sync timer already keep `/usr/share/nginx/html` in sync with S3.
   - You only need to upload a new demo video manually (default key `demo-video.mp4`).

## Functional Highlights

- **Account creation & login** – `auth_signup` hashes credentials with `scrypt`, `auth_login` validates them and mints a JWT signed with the secret you pass via `TF_VAR_jwt_secret`.
- **Video playback** – The frontend pulls `index.html`, `styles.css`, `app.js`, and your demo video via Nginx behind the load balancer. The placeholder URLs are replaced during the EC2 sync process so browsers always call the correct API.
- **Community interactions** – Authenticated users can create comments and reactions that land in DynamoDB tables with pay-per-request billing.
- **Operational visibility** – Every Lambda writes lightweight log entries to the `logs` table so you can troubleshoot flows without CloudWatch.
- **Automated delivery** – CodePipeline → CodeBuild triggers Terraform, provisions the VPC/ALB/ASG/API, and syncs the frontend bundle without manual steps.

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

 Wo du die fehlenden Infos bekommst:
AWS Account kostenlos erstellen:

Gehe zu: https://aws.amazon.com/free/
"Create a free account" → Kostenlose Registrierung
Kreditkarte wird benötigt (aber nicht belastet bei Free Tier)
AWS Credentials (Access Keys):

Gehe zu: https://console.aws.amazon.com/iam/
Erstelle neuen IAM User: streamflix-deploy
Weise diese Policies zu:
AmazonS3FullAccess
AWSLambda_FullAccess
AmazonDynamoDBFullAccess
AmazonAPIGatewayAdministrator
IAMFullAccess
CloudWatchLogsFullAccess
Erstelle Access Key → Speichere ID + Secret sicher!
AWS CLI installieren:

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws configure  # Gib deine Credentials ein

 Alles kostenlos im AWS Free Tier:
✅ Konfiguration optimiert für Free Tier:

Lambda: 128MB RAM (Minimum), 30s Timeout
DynamoDB: Pay-per-Request (bereits konfiguriert)
Keine zusätzlichen Services (CloudFront, etc.)
📊 Free Tier Limits (EU-Central-1):

S3: 5GB Storage + 20.000 GET + 2.000 PUT Requests
Lambda: 1M Requests + 400.000 GB-Sekunden
API Gateway: 1M Requests
DynamoDB: 25GB + 200M Requests
CloudWatch Logs: 5GB
🚀 Deployment (kostenlos):
# 1. Remote State Backend erstellen
make backend

# 2. JWT Secret setzen
export TF_VAR_jwt_secret=$(openssl rand -base64 32)

# 3. Deployen
make deploy-dev

# 4. Kosten überwachen
make check-costs
 Dokumentation:
AWS_FREE_SETUP.md - Vollständige Anleitung
README.md - Projekt-Übersicht
QUICKSTART.md - Schnellstart
⚠️ Wichtig für kostenlos bleiben:
Überwache Billing: https://console.aws.amazon.com/billing/
Aktiviere Free Tier Alerts
Lösche alles mit: make destroy-dev
Halte Videos < 5GB
Limitiere Requests auf < 1000/Tag
