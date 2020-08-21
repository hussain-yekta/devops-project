# Service runtime arguments
SHELL := /bin/bash
service = jenkins-312
namespace = jenkins
kubectl := kubectl -n $(namespace)
region = us-east-1
version = latest

# DON'T change the variables below
repository := mshaibek/$(service)
image := $(repository):$(version)
kubectl := kubectl -n $(namespace)
aws := aws --region $(region)

# ECR registry parameters (for login, push targets)
# This uses the current aws config profile (or $AWV_PROFILE)
account := $(shell $(aws) sts get-caller-identity --output text --query 'Account')
registry := $(shell echo $(account).dkr.ecr.us-east-1.amazonaws.com)
login := $(shell $(aws) ecr get-login --registry-ids $(account) --no-include-email)

default: help

# Lists all available targets
help:
	@make -qp | awk -F':' '/^[a-z0-9][^$$#\/\t=]*:([^=]|$$)/ {split($$1,A,/ /);for(i in A)print A[i]}' | sort

# Logs into the docker registry
login:
	@echo $(registry)
	@$(login)

# Builds an image
build: login
	docker build -t $(image) .

# Pushes an image into the remote registry
push: login
	docker tag $(image) $(registry)/$(image)
	$(aws) ecr describe-images --repository-name $(repository) --image-ids imageTag=$(version) \
		|| docker push $(registry)/$(image)

run:
	$(kubectl) apply -f kubernetes.yaml

stop:
	$(kubectl) delete -f kubernetes.yaml

delete-pvc: stop-jenkins
	$(kubectl) delete pvc jenkins-home-jenkins-0

privilege:
	kubectl apply -f clusterrole-binding.yaml
	kubectl apply -f psp.yaml
