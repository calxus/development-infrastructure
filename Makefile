SHELL:=bash

.PHONY: bootstrap
bootstrap: ## Bootstrap local environment for first use
	pip3 install --user Jinja2 boto3
	python3 bootstrap_terraform.py; 
	terraform fmt -recursive

.PHONY: terraform-init
terraform-init: ## Run `terraform init` from repo root
	terraform init

.PHONY: terraform-plan
terraform-plan: ## Run `terraform plan` from repo root
	terraform plan

.PHONY: terraform-apply
terraform-apply: ## Run `terraform apply` from repo root
	terraform apply 