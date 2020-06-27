SHELL:=bash

.PHONY: bootstrap
bootstrap: 
	pip3 install --user Jinja2 boto3
	python3 bootstrap_terraform.py; 
	terraform fmt -recursive

.PHONY: ssh-tactical
ssh-tactical:
	@{ \
		aws s3 cp s3://`aws s3 ls | cut -d " " -f 3`/config/tactical.pem tactical.pem && chmod 400 tactical.pem; \
		ssh -i tactical.pem kali@`aws ec2 describe-instances | jq '.Reservations | .[].Instances' | jq -c 'select(.[].State.Name | contains("running"))' | jq '.[].PublicIpAddress' | tr --delete \"`; \
	}

.PHONY: terraform-init
terraform-init: 
	terraform init

.PHONY: terraform-plan
terraform-plan: 
	terraform plan

.PHONY: terraform-apply
terraform-apply: 
	terraform apply 

.PHONY: ip-tactical
ip-tactical:
	@aws ec2 describe-instances | jq '.Reservations | .[].Instances' | jq -c 'select(.[].State.Name | contains("running"))' | jq '.[].PublicIpAddress'

.PHONY: pem-tactical
pem-tactical:
	@aws s3 cp s3://$(aws s3 ls | cut -d " " -f 3)/config/tactical.pem tactical.pem && chmod 400 tactical.pem

.PHONY: stop-tactical
stop-tactical:
	@aws ec2 stop-instances --instance-ids `aws ec2 describe-instances | jq '.Reservations | .[].Instances' | jq -c 'select(.[].State.Name | contains("running"))' | jq '.[].InstanceId' | tr --delete \"`

.PHONY: start-tactical
start-tactical:
	@aws ec2 start-instances --instance-ids `aws ec2 describe-instances | jq '.Reservations | .[].Instances' | jq -c 'select(.[].State.Name | contains("stopped"))' | jq '.[].InstanceId' | tr --delete \"`