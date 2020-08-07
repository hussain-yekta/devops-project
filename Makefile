KubeDnsVersion = 1.6.6
KubeProxyVersion = 1.17.7
ClusterAutoScalerVersion = 1.17.3
CniMajorVersion = 1.6
CniVersion = 1.6

secret-generator:
	aws cloudformation create-stack \
		--capabilities CAPABILITY_IAM \
		--stack-name cfn-secret-provider \
		--template-body file://cloudformation/cfn-resource-provider.yaml
	aws cloudformation wait stack-create-complete  --stack-name cfn-secret-provider

delete-secret-generator:
	aws cloudformation delete-stack --stack-name cfn-secret-provider

sshkeys:
	aws cloudformation create-stack --stack-name eks-node-secrets --template-body file://cloudformation/ec2-sshkeypair.yaml

delete-sshkeys:
	aws cloudformation delete-stack --stack-name eks-node-secrets

get-private-key:
	aws ssm get-parameter --name /eks-node-secrets/private-key --with-decryption --output text --query 'Parameter.Value' > ~/.ssh/eks-node-secrets.pem
	chmod 600 ~/.ssh/eks-node-secrets.pem

eks:
	aws cloudformation create-stack --stack-name eks-dev \
		--template-body file://cloudformation/eks.yaml \
		--capabilities CAPABILITY_IAM \
		--parameter ParameterKey=VpcBlock,ParameterValue=10.20.0.0/16 \
			ParameterKey=ClusterVersion,ParameterValue=1.15 \
			ParameterKey=Subnet01Block,ParameterValue=10.20.64.0/18 \
			ParameterKey=Subnet02Block,ParameterValue=10.20.128.0/18 \
			ParameterKey=Subnet03Block,ParameterValue=10.20.192.0/18 \
			ParameterKey=Subnet01Az,ParameterValue=0 \
			ParameterKey=Subnet02Az,ParameterValue=1 \
			ParameterKey=Subnet03Az,ParameterValue=2

update-cluster-version:
	aws eks update-cluster-version --name eks-dev --kubernetes-version 1.17

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

delete-eks:
	aws cloudformation delete-stack --stack-name eks-dev

workers:
	aws cloudformation create-stack \
		--capabilities CAPABILITY_IAM \
		--stack-name eks-dev-workers-spot-instance \
		--template-body file://cloudformation/amazon-eks-nodegroup.yaml \
		--parameter ParameterKey=ClusterControlPlaneSecurityGroup,ParameterValue=sg-081d7a210689c259c \
			ParameterKey=ClusterName,ParameterValue=eks-dev \
			ParameterKey=KeyName,ParameterValue=eks-node-secrets-keypair \
			ParameterKey=NodeAutoScalingGroupDesiredCapacity,ParameterValue=2 \
			ParameterKey=NodeAutoScalingGroupMaxSize,ParameterValue=5 \
			ParameterKey=NodeAutoScalingGroupMinSize,ParameterValue=1 \
			ParameterKey=NodeGroupName,ParameterValue=eks-dev-workers \
			ParameterKey=NodeImageId,ParameterValue=ami-0842e3f57a7f2db2e \
			ParameterKey=NodeInstanceType,ParameterValue=t2.micro \
			ParameterKey=NodeVolumeSize,ParameterValue=8 \
			ParameterKey=SpotPrice,ParameterValue=0.0116 \
			ParameterKey=Subnets,ParameterValue=subnet-0474af036f25654cc\\,subnet-00383d6a872fa1ed9\\,subnet-08536f57e2fe76f83 \
			ParameterKey=VpcId,ParameterValue=vpc-06d6cf0bec368d195
	aws cloudformation wait stack-create-complete  --stack-name cfn-secret-provider
	kubectl apply -f kubernetes/aws-auth-cm.yaml

update-workers:
	aws cloudformation update-stack \
		--capabilities CAPABILITY_IAM \
		--stack-name eks-dev-workers-spot-instance \
		--template-body file://cloudformation/amazon-eks-nodegroup.yaml \
		--parameter ParameterKey=ClusterControlPlaneSecurityGroup,ParameterValue=sg-081d7a210689c259c \
			ParameterKey=ClusterName,ParameterValue=eks-dev \
			ParameterKey=KeyName,ParameterValue=eks-node-secrets-keypair \
			ParameterKey=NodeAutoScalingGroupDesiredCapacity,ParameterValue=3 \
			ParameterKey=NodeAutoScalingGroupMaxSize,ParameterValue=10 \
			ParameterKey=NodeAutoScalingGroupMinSize,ParameterValue=1 \
			ParameterKey=NodeGroupName,ParameterValue=eks-dev-workers \
			ParameterKey=NodeImageId,ParameterValue=ami-0842e3f57a7f2db2e \
			ParameterKey=NodeInstanceType,ParameterValue=t2.medium \
			ParameterKey=SpotPrice,ParameterValue=0.0464 \
			ParameterKey=NodeVolumeSize,ParameterValue=8 \
			ParameterKey=Subnets,ParameterValue=subnet-0474af036f25654cc\\,subnet-00383d6a872fa1ed9\\,subnet-08536f57e2fe76f83 \
			ParameterKey=VpcId,ParameterValue=vpc-06d6cf0bec368d195

delete-workers:
	aws cloudformation delete-stack --stack-name eks-dev-workers

db-vpc:
	aws cloudformation create-stack \
		--stack-name eks-dev-db-vpc \
		--template-body file://cloudformation/db-vpc.yaml \
		--parameter ParameterKey=VpcBlock,ParameterValue=10.30.0.0/16 \
			ParameterKey=Subnet01Block,ParameterValue=10.30.64.0/18 \
			ParameterKey=Subnet02Block,ParameterValue=10.30.128.0/18 \
			ParameterKey=Subnet03Block,ParameterValue=10.30.192.0/18

delete-db-vpc:
	#read -p "Are you sure? It's a Database VPC. Confirm yes/no:"
	# echo
	#if [[ "$$REPLY" == "no" ]]; then exit 1 ; fi
	aws cloudformation delete-stack --stack-name eks-dev-db-vpc

db:
	aws cloudformation create-stack \
		--stack-name db-dev \
		--template-body file://cloudformation/db.yaml \
		--parameter ParameterKey=ParentVPCStack,ParameterValue=eks-dev-db-vpc \
			ParameterKey=ParentSecurityGroupIds,ParameterValue=sg-037348d170308350a \
			ParameterKey=DBInstanceID,ParameterValue=db-dev \
			ParameterKey=DBName,ParameterValue=mydatabase \
			ParameterKey=DBUsername,ParameterValue=root \
			ParameterKey=Application,ParameterValue=ECommerceApp \
			ParameterKey=ServiceOwnersEmailContact,ParameterValue=shaibekovmb@gmail.com \
			ParameterKey=Confidentiality,ParameterValue=private

peering:
	bin/aws-vpc-create-peering-connection.sh vpc-06d6cf0bec368d195 vpc-0662c961b3030e897 cloudformation/eks-dev-db.yaml

delete-peering:
	aws cloudformation delete-stack --stack-name eks-dev-db-peering

ssh-bastion:
	aws cloudformation create-stack \
		--stack-name eks-dev-bastion \
		--template-body file://cloudformation/bastion.yaml \
		--parameter ParameterKey=KeyName,ParameterValue=eks-node-secrets-keypair \
			ParameterKey=Ami,ParameterValue=ami-0323c3dd2da7fb37d \
			ParameterKey=VpcID,ParameterValue=vpc-06d6cf0bec368d195 \
			ParameterKey=SubnetID,ParameterValue=subnet-0474af036f25654cc

delete-ssh-bastion:
	aws cloudformation delete-stack --stack-name eks-dev-bastion

jenkins:
	kubectl apply -f jenkins-master/kubernetes.yaml

stop-jenkins:
	kubectl delete -f jenkins-master/kubernetes.yaml

delete-jenkins: stop-jenkins
	kubectl delete pvc jenkins-home-jenkins-0

nginx:
	kubectl apply -f kubernetes/ingress-nginx.yaml

delete-nginx:
	kubectl delete -f kubernetes/ingress-nginx.yaml

run-all: secret-generator sshkeys eks workers db-vpc db

privilege-jenkins:
	kubectl apply -f clusterrole-binding.yaml
	kubectl apply -f psp.yaml
