# Get the current cluster name
cluster = $(shell basename $$(kubectl config current-context))
# configutation
version = 1.0
namespace = monitoring
include clusters/$(cluster)/config
region = us-east-1

# do not change the variables below
kubectl := kubectl -n $(namespace)

replacements="\
s/NAMESPACE/$(namespace)/g;\
s/STORAGESIZE/$(storagesize)/g;\
s/CLUSTER/$(cluster)/g;\
s/RETENTIONPERIOD/$(retentionPeriod)/g\
"

default: help

# list the available targets
help:
	@echo "Available targets:"
	@make -qp | awk -F':' '/^[a-z0-9][^$$#\/\t=]*:([^=]|$$)/ {split($$1,A,/ /);for(i in A)print A[i]}' | sort

namespace:
	@cat namespace.yml | sed $(replacements) | kubectl apply -f -

run: namespace
	@cat prometheus-server/auth.yml | sed $(replacements) | kubectl apply -f -
	@cat prometheus-server/pvc.yml | sed $(replacements) | kubectl apply -f -
	@cat prometheus-server/configmap.yml | sed $(replacements) | kubectl apply -f -
	@cat prometheus-server/deployment.yml | sed $(replacements) | kubectl apply -f -
	@cat prometheus-server/service.yml | sed $(replacements) | kubectl apply -f -
	@###
	@cat kube-state-metrics/auth.yml | sed $(replacements) | kubectl apply -f -
	@cat kube-state-metrics/deployment.yml | sed $(replacements) | kubectl apply -f -
	@cat kube-state-metrics/service.yml | sed $(replacements) | kubectl apply -f -
	@###
	@cat node-exporter/auth.yml | sed $(replacements) | kubectl apply -f -
	@cat node-exporter/daemonset.yml | sed $(replacements) | kubectl apply -f -
	@cat node-exporter/service.yml | sed $(replacements) | kubectl apply -f -

stop:
	@cat prometheus-server/deployment.yml | sed $(replacements) | kubectl delete -f - --ignore-not-found
	@cat prometheus-server/service.yml | sed $(replacements) | kubectl delete -f - --ignore-not-found
	@cat kube-state-metrics/deployment.yml | sed $(replacements) | kubectl delete -f - --ignore-not-found
	@cat kube-state-metrics/service.yml | sed $(replacements) | kubectl delete -f - --ignore-not-found
	@cat node-exporter/daemonset.yml | sed $(replacements) | kubectl delete -f - --ignore-not-found
	@cat node-exporter/service.yml | sed $(replacements) | kubectl delete -f - --ignore-not-found

clean: stop
	@cat prometheus-server/auth.yml | sed $(replacements) | kubectl delete -f - --ignore-not-found
	@cat prometheus-server/configmap.yml | sed $(replacements) | kubectl delete -f - --ignore-not-found
	@cat kube-state-metrics/auth.yml | sed $(replacements) | kubectl delete -f - --ignore-not-found
	@cat node-exporter/auth.yml | sed $(replacements) | kubectl delete -f - --ignore-not-found

destroy: clean
	@# ReclaimPolicy is Delete, pv and ebs volume will also be deleted once pvc is deleted. If pv is deleted manually before k8s deletes it - ebs volume in aws will not be deleted
	@cat prometheus-server/pvc.yml | sed $(replacements) | kubectl delete -f - --ignore-not-found

watch:
	@$(kubectl) get pods -w

.ONESHELL:
# After resize you will have to wait at least 6 hours before another modification per EBS volume
# Resizing might take anywhere between couple minutes to 10-15 minutes
resize-volume:
	@cat prometheus-server/pvc.yml | sed $(replacements) | kubectl apply -f -
	$(kubectl) wait pvc/prometheus-server --for=condition=FileSystemResizePending --timeout=30m
	@$(eval podname := $(shell $(kubectl) get pods -lapp=prometheus,component=server -o name))
	@$(kubectl) delete $(podname)

disk-usage:
	@$(kubectl) exec -it $$($(kubectl) get pod \
		-l "app=prometheus,component=server" -o=jsonpath='{.items[0].metadata.name}') \
		-c prometheus-server -- df -h

forward:
	@$(kubectl) port-forward $$($(kubectl) get pod \
		-l "app=prometheus,component=server" -o jsonpath="{.items[0].metadata.name}")  9090
