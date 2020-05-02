


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
