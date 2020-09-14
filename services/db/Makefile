service = eks-dev
region = us-east-1
aws := aws --region $(region)

db-vpc:
	@$(aws) cloudformation create-stack \
		--stack-name $(service)-db-vpc \
		--template-body file://db-vpc.yaml \
		--parameter ParameterKey=VpcBlock,ParameterValue=10.30.0.0/16 \
			ParameterKey=Subnet01Block,ParameterValue=10.30.64.0/18 \
			ParameterKey=Subnet02Block,ParameterValue=10.30.128.0/18 \
			ParameterKey=Subnet03Block,ParameterValue=10.30.192.0/18

delete-db-vpc:
	#read -p "Are you sure? It's a Database VPC. Confirm yes/no:"
	# echo
	#if [[ "$$REPLY" == "no" ]]; then exit 1 ; fi
	@$(aws) cloudformation delete-stack --stack-name $(service)-db-vpc

db:
	@$(aws) cloudformation create-stack \
		--stack-name db-dev \
		--template-body file://db.yaml \
		--parameter ParameterKey=ParentVPCStack,ParameterValue=$(service)-db-vpc \
			ParameterKey=ParentSecurityGroupIds,ParameterValue=sg-037348d170308350a \
			ParameterKey=DBInstanceID,ParameterValue=db-dev \
			ParameterKey=DBName,ParameterValue=mydatabase \
			ParameterKey=DBUsername,ParameterValue=root \
			ParameterKey=Application,ParameterValue=ECommerceApp \
			ParameterKey=ServiceOwnersEmailContact,ParameterValue=shaibekovmb@gmail.com \
			ParameterKey=Confidentiality,ParameterValue=private

peering:
	../../bin/aws-vpc-create-peering-connection.sh vpc-06d6cf0bec368d195 vpc-0662c961b3030e897 $(service)-db.yaml

delete-peering:
	@$(aws) cloudformation delete-stack --stack-name $(service)-db-peering
