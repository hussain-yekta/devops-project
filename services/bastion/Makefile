service = eks-dev
region = us-east-1
aws := aws --region $(region)

ssh-bastion:
	@$(aws) cloudformation create-stack \
		--stack-name $(service)-bastion \
		--template-body file://bastion.yaml \
		--parameter ParameterKey=KeyName,ParameterValue=eks-node-secrets-keypair \
			ParameterKey=Ami,ParameterValue=ami-0323c3dd2da7fb37d \
			ParameterKey=VpcID,ParameterValue=vpc-06d6cf0bec368d195 \
			ParameterKey=SubnetID,ParameterValue=subnet-0474af036f25654cc

delete-ssh-bastion:
	@$(aws) cloudformation delete-stack --stack-name $(service)-bastion
