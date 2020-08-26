service = eks-dev
region = us-east-1
aws := aws --region $(region)

include clusters/$(service)/$(region)/$(service)

SpotPrice = 0.0464
NodeGroupName = eks-dev-workers
WorkersStackName = eks-dev-workers

default: help

# Lists the available targets
help:
	@make -qp | awk -F':' '/^[a-z0-9][^$$#\/\t=]*:([^=]|$$)/ {split($$1,A,/ /);for(i in A)print A[i]}' | sort

secret-generator:
	@$(aws) cloudformation create-stack \
		--capabilities CAPABILITY_IAM \
		--stack-name cfn-secret-provider \
		--template-body file://cloudformation/cfn-resource-provider.yaml
	@$(aws) cloudformation wait stack-create-complete  --stack-name cfn-secret-provider

delete-secret-generator:
	@$(aws) cloudformation delete-stack --stack-name cfn-secret-provider

sshkeys:
	@$(aws) cloudformation create-stack --stack-name eks-node-secrets --template-body file://cloudformation/ec2-sshkeypair.yaml

delete-sshkeys:
	@$(aws) cloudformation delete-stack --stack-name eks-node-secrets

get-private-key:
	$(aws) ssm get-parameter --name /eks-node-secrets/private-key --with-decryption --output text --query 'Parameter.Value' > ~/.ssh/eks-node-secrets.pem
	@chmod 600 ~/.ssh/eks-node-secrets.pem

eks:
	$(aws) cloudformation create-stack --stack-name $(service) \
		--template-body file://cloudformation/eks.yaml \
		--capabilities CAPABILITY_IAM \
		--parameter ParameterKey=VpcBlock,ParameterValue=$(VpcBlock) \
			ParameterKey=ClusterVersion,ParameterValue=$(ClusterVersion) \
			ParameterKey=Subnet01Block,ParameterValue=$(Subnet01Block) \
			ParameterKey=Subnet02Block,ParameterValue=$(Subnet02Block) \
			ParameterKey=Subnet03Block,ParameterValue=$(Subnet03Block) \
			ParameterKey=Subnet01Az,ParameterValue=$(Subnet01Az) \
			ParameterKey=Subnet02Az,ParameterValue=$(Subnet02Az) \
			ParameterKey=Subnet03Az,ParameterValue=$(Subnet03Az)
	$(aws) cloudformation wait stack-create-complete --stack-name $(service)
	@echo "waiting for the cluster to start, can take 10 minutes..."
	$(aws) eks describe-cluster --name $(service) --query cluster.status

update-cluster-version:
	@$(aws) eks update-cluster-version --name $(service) --kubernetes-version $(ClusterVersion)

delete-eks:
	@$(aws) cloudformation delete-stack --stack-name $(service)

iam:
	@$(aws) cloudformation create-stack --stack-name $(service)-iam \
		--template-body file://iam.yaml \
		--capabilities CAPABILITY_NAMED_IAM \
		--parameters ParameterKey=NodeStack,ParameterValue=$(WorkersStackName)
	@$(aws) cloudformation wait stack-create-complete --stack-name $(service)-iam

# Configures and deploys the worker nodes
replacements="\
s|<node-instance-role>|$(NodeInstanceRole)|g;\
"

workers:
	@$(eval securitygroups := $(shell $(aws) cloudformation describe-stacks \
		--stack-name $(service) \
		--query 'Stacks[0].Outputs[?OutputKey==`SecurityGroups`].OutputValue' \
		--output text | sed 's/,/\\\\,/g'))
	@$(eval subnetids := $(shell $(aws) cloudformation describe-stacks \
		--stack-name $(service) \
		--query 'Stacks[0].Outputs[?OutputKey==`SubnetIds`].OutputValue' \
		--output text | sed 's/,/\\\\,/g'))
	@$(eval vpcid := $(shell $(aws) cloudformation describe-stacks \
		--stack-name $(service) \
		--query 'Stacks[0].Outputs[?OutputKey==`VpcId`].OutputValue' \
		--output text))
	@$(eval nodeInstanceProfile :=  $(shell $(aws) cloudformation describe-stacks \
	--stack-name $(service)-iam \
	--query 'Stacks[0].Outputs[?OutputKey==`NodeInstanceProfile`].OutputValue' --output text | rev | cut -f 1 -d '/' | rev))
	$(eval NodeInstanceRole := $(shell $(aws) cloudformation describe-stacks \
	--stack-name $(service)-iam \
	--query 'Stacks[0].Outputs[?OutputKey==`NodeInstanceRole`].OutputValue' \
	--output text))
	@$(aws) cloudformation create-stack \
		--capabilities CAPABILITY_IAM \
		--stack-name $(WorkersStackName) \
		--template-body file://amazon-eks-nodegroup.yaml \
		--parameter ParameterKey=ClusterControlPlaneSecurityGroup,ParameterValue=$(securitygroups) \
			ParameterKey=ClusterName,ParameterValue=$(service) \
			ParameterKey=KeyName,ParameterValue=eks-node-secrets-keypair \
			ParameterKey=NodeAutoScalingGroupDesiredCapacity,ParameterValue=$(asgDesired) \
			ParameterKey=NodeAutoScalingGroupMaxSize,ParameterValue=$(asgMax) \
			ParameterKey=NodeAutoScalingGroupMinSize,ParameterValue=$(asgMin) \
			ParameterKey=NodeGroupName,ParameterValue=$(NodeGroupName) \
			ParameterKey=NodeImageId,ParameterValue=$(ami) \
			ParameterKey=NodeInstanceType,ParameterValue=$(instanceType) \
			ParameterKey=NodeInstanceProfile,ParameterValue=$(nodeInstanceProfile) \
			ParameterKey=NodeVolumeSize,ParameterValue=$(volumeSize) \
			ParameterKey=SpotPrice,ParameterValue=$(SpotPrice) \
			ParameterKey=Subnets,ParameterValue=$(subnetids) \
			ParameterKey=VpcId,ParameterValue=$(vpcid)
	@$(aws) cloudformation wait stack-create-complete  --stack-name $(WorkersStackName)
	@cat ../../kubernetes/aws-auth-cm.yaml | sed $(replacements) | kubectl apply -f -

update-workers:
	@$(eval securitygroups := $(shell $(aws) cloudformation describe-stacks \
		--stack-name $(service) \
		--query 'Stacks[0].Outputs[?OutputKey==`SecurityGroups`].OutputValue' \
		--output text | sed 's/,/\\\\,/g'))
	@$(eval subnetids := $(shell $(aws) cloudformation describe-stacks \
		--stack-name $(service) \
		--query 'Stacks[0].Outputs[?OutputKey==`SubnetIds`].OutputValue' \
		--output text | sed 's/,/\\\\,/g'))
	@$(eval vpcid := $(shell $(aws) cloudformation describe-stacks \
		--stack-name $(service) \
		--query 'Stacks[0].Outputs[?OutputKey==`VpcId`].OutputValue' \
		--output text))
		@$(eval nodeInstanceProfile :=  $(shell $(aws) cloudformation describe-stacks \
		--stack-name $(service)-iam \
		--query 'Stacks[0].Outputs[?OutputKey==`NodeInstanceProfile`].OutputValue' \
		--output text))
		$(eval NodeInstanceRole := $(shell $(aws) cloudformation describe-stacks \
		--stack-name $(service)-iam \
		--query 'Stacks[0].Outputs[?OutputKey==`NodeInstanceRole`].OutputValue' \
		--output text))
	@$(aws) cloudformation update-stack \
		--capabilities CAPABILITY_IAM \
		--stack-name $(WorkersStackName) \
		--template-body file://amazon-eks-nodegroup.yaml \
		--parameter ParameterKey=ClusterControlPlaneSecurityGroup,ParameterValue=$(securitygroups) \
			ParameterKey=ClusterName,ParameterValue=$(service) \
			ParameterKey=KeyName,ParameterValue=eks-node-secrets-keypair \
			ParameterKey=NodeAutoScalingGroupDesiredCapacity,ParameterValue=$(asgDesired) \
			ParameterKey=NodeAutoScalingGroupMaxSize,ParameterValue=$(asgMax) \
			ParameterKey=NodeAutoScalingGroupMinSize,ParameterValue=$(asgMin) \
			ParameterKey=NodeGroupName,ParameterValue=$(NodeGroupName) \
			ParameterKey=NodeImageId,ParameterValue=$(ami) \
			ParameterKey=NodeInstanceType,ParameterValue=$(instanceType) \
			ParameterKey=NodeInstanceProfile,ParameterValue=$(nodeInstanceProfile) \
			ParameterKey=SpotPrice,ParameterValue=$(SpotPrice) \
			ParameterKey=NodeVolumeSize,ParameterValue=$(volumeSize) \
			ParameterKey=Subnets,ParameterValue=$(subnetids)
			ParameterKey=VpcId,ParameterValue=$(vpcid)
	$(aws) cloudformation wait stack-update-complete --stack-name $(WorkersStackName)
	@cat ../../kubernetes/aws-auth-cm.yaml | sed $(replacements) | kubectl apply -f -

delete-workers:
	@$(aws) cloudformation delete-stack --stack-name $(WorkersStackName)
	$(aws) cloudformation wait stack-delete-complete --stack-name $(WorkersStackName)

update-daemonset:
	kubectl set image daemonset.apps/kube-proxy \
		-n kube-system \
		kube-proxy=602401143452.dkr.ecr.us-west-2.amazonaws.com/eks/kube-proxy:v$(KubeProxyVersion)

update-dns:
	kubectl set image --namespace kube-system deployment.apps/coredns \
		coredns=602401143452.dkr.ecr.us-west-2.amazonaws.com/eks/coredns:v$(KubeDnsVersion)

update-cni:
	kubectl apply -f https://raw.githubusercontent.com/aws/amazon-vpc-cni-k8s/release-$(CniVersion)/config/v$(CniMajorVersion)/aws-k8s-cni.yaml

update-cluster-autoscaler:
	kubectl -n kube-system set image deployment.apps/cluster-autoscaler cluster-autoscaler=us.gcr.io/k8s-artifacts-prod/autoscaling/cluster-autoscaler:v$(ClusterAutoScalerVersion)

disable-autoscaler:
	kubectl scale deployments/cluster-autoscaler --replicas=0 -n kube-system

enable-autoscaler:
	kubectl scale deployments/cluster-autoscaler --replicas=1 -n kube-system
