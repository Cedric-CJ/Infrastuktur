.PHONY: help install-deps deploy-dev deploy-prod destroy-dev destroy-prod fmt validate clean backend check-costs

help: ## Zeigt diese Hilfe an
	@echo "AWS Streaming MVP - Terraform Commands"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'

backend: ## Erstellt S3-Bucket und DynamoDB-Tabelle für Remote State
	@./scripts/create-backend.sh

check-costs: ## Überprüft AWS Free Tier Nutzung und Kosten
	@./scripts/check-costs.sh

install-deps: ## Installiert Lambda-Dependencies
	@echo "📦 Installing Lambda dependencies..."
	@cd lambdas/auth_signup && npm install --omit=dev
	@cd lambdas/auth_login && npm install --omit=dev
	@cd lambdas/comments_write && npm install --omit=dev
	@cd lambdas/reactions_write && npm install --omit=dev
	@echo "✅ Done"

deploy-dev: install-deps ## Deployt die Dev-Umgebung
	@echo "🚀 Deploying to DEV..."
	@cd terraform/envs/dev && terraform init && terraform apply
	@echo "✅ Deployment complete!"
	@cd terraform/envs/dev && terraform output

deploy-prod: install-deps ## Deployt die Prod-Umgebung
	@echo "🚀 Deploying to PROD..."
	@cd terraform/envs/prod && terraform init && terraform apply
	@echo "✅ Deployment complete!"
	@cd terraform/envs/prod && terraform output

plan-dev: install-deps ## Zeigt den Terraform-Plan für Dev
	@cd terraform/envs/dev && terraform init && terraform plan

plan-prod: install-deps ## Zeigt den Terraform-Plan für Prod
	@cd terraform/envs/prod && terraform init && terraform plan

destroy-dev: ## Löscht die Dev-Infrastruktur
	@echo "⚠️  Destroying DEV environment..."
	@cd terraform/envs/dev && terraform destroy

destroy-prod: ## Löscht die Prod-Infrastruktur
	@echo "⚠️  Destroying PROD environment..."
	@cd terraform/envs/prod && terraform destroy

fmt: ## Formatiert alle Terraform-Dateien
	@terraform fmt -recursive terraform/

validate: ## Validiert alle Terraform-Konfigurationen
	@cd terraform/envs/dev && terraform init -backend=false && terraform validate
	@cd terraform/envs/prod && terraform init -backend=false && terraform validate
	@echo "✅ Validation successful"

clean: ## Löscht generierte Dateien und Caches
	@echo "🧹 Cleaning up..."
	@find . -type f -name "*.zip" -delete
	@find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	@find . -type d -name "node_modules" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name "terraform.tfstate*" -delete 2>/dev/null || true
	@find . -type f -name ".terraform.lock.hcl" -delete 2>/dev/null || true
	@echo "✅ Cleanup complete"

outputs-dev: ## Zeigt die Outputs der Dev-Umgebung
	@cd terraform/envs/dev && terraform output

outputs-prod: ## Zeigt die Outputs der Prod-Umgebung
	@cd terraform/envs/prod && terraform output

init-dev: ## Initialisiert Terraform für Dev
	@cd terraform/envs/dev && terraform init

init-prod: ## Initialisiert Terraform für Prod
	@cd terraform/envs/prod && terraform init
