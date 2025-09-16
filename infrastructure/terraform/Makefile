.PHONY: help init plan apply destroy validate format lint clean

# Default environment
ENV ?= dev

# Help target
help:
	@echo "Available targets:"
	@echo "  init      - Initialize Terraform"
	@echo "  plan      - Plan Terraform changes"
	@echo "  apply     - Apply Terraform changes"
	@echo "  destroy   - Destroy Terraform resources"
	@echo "  validate  - Validate Terraform configuration"
	@echo "  format    - Format Terraform files"
	@echo "  lint      - Lint Terraform files"
	@echo "  clean     - Clean Terraform files"
	@echo ""
	@echo "Usage: make <target> ENV=<environment>"
	@echo "Environments: dev, staging, prod"

# Initialize Terraform
init:
	terraform init -backend-config=backend-$(ENV).hcl

# Plan changes
plan:
	terraform plan -var-file=environments/$(ENV).tfvars -out=tfplan-$(ENV)

# Apply changes
apply:
	terraform apply tfplan-$(ENV)

# Destroy resources
destroy:
	terraform destroy -var-file=environments/$(ENV).tfvars

# Validate configuration
validate:
	terraform validate

# Format code
format:
	terraform fmt -recursive

# Lint with tflint
lint:
	tflint --init
	tflint

# Clean temporary files
clean:
	rm -f tfplan-*
	rm -rf .terraform/
	rm -f .terraform.lock.hcl