# Get the current Main Cluster name
cluster = $(shell basename $$(kubectl config current-context))
namespace = monitoring

# in order to change service, all grafana resource names and labels should be changed to SERVICE_NAME
service = grafana
include clusters/$(cluster)

# do not change these
kubectl := kubectl -n $(namespace)
aws := aws --region $(region)


# Configure and deploy the service
replacements="\
s/SERVICE_NAME/$(service)/g;\
s/NAMESPACE/$(namespace)/g;\
s/HOSTNAME/$(hostname)/g;\
"

# list the available targets
help:
	@make -qp | awk -F':' '/^[a-z0-9][^$$#\/\t=]*:([^=]|$$)/ {split($$1,A,/ /);for(i in A)print A[i]}' | sort

default: run

namespace:
	@cat namespace.yml | sed $(replacements) | kubectl apply -f -

run: namespace clean-configmaps
	@cat auth.yml | sed $(replacements) | $(kubectl) apply -f -
	@cat configs/configmap.yml | sed $(replacements) | $(kubectl) apply -f -
	@$(kubectl) create configmap grafana-datasources  --from-file configs/datasource.yml
	@$(kubectl) create configmap grafana-general-dashboards --from-file dashboards/common \
		--dry-run -o yaml | sed $(replacements) | $(kubectl) create -f -
	@$(kubectl) create configmap grafana-dashboards --from-file configs/dashboard.yml \
		--dry-run -o yaml | sed $(replacements) | $(kubectl) create -f -
	@cat service.yml | sed $(replacements) | $(kubectl) apply -f -

clean-configmaps:
	@$(kubectl) delete configmap grafana-datasources grafana-general-dashboards grafana-dashboards --ignore-not-found

stop:
	@cat service.yml | sed $(replacements) | kubectl delete -f - --ignore-not-found

clean: stop clean-configmaps
	@cat auth.yml | sed $(replacements) | kubectl delete -f - --ignore-not-found
	@cat configmap.yml | sed $(replacements) | kubectl delete -f - --ignore-not-found


purge: clean

# Inject secrets from AWS to kube
inject-secrets:
	@bin/k8s-secrets-inject-secrets $(service) $(namespace) ./aws/secrets

# Inject secrets from file to aws
create-secrets:
	@bin/aws-secretsmanager-create-secrets $(service) ./aws/secrets

# Inject secrets from file to aws
update-secrets:
	@bin/aws-secretsmanager-update-secrets $(service) ./aws/secrets

aws-secrets: create-secrets
