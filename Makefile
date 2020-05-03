


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

delete-eks:
	aws cloudformation delete-stack --stack-name eks-dev

workers:
	aws cloudformation create-stack \
		--capabilities CAPABILITY_IAM \
		--stack-name eks-dev-workers \
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
			ParameterKey=Subnets,ParameterValue=subnet-0474af036f25654cc\\,subnet-00383d6a872fa1ed9\\,subnet-08536f57e2fe76f83 \
			ParameterKey=VpcId,ParameterValue=vpc-06d6cf0bec368d195
	aws cloudformation wait stack-create-complete  --stack-name cfn-secret-provider
	kubectl apply -f aws-auth-cm.yaml

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
