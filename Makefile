


secret-generator:
	aws cloudformation create-stack \
		--capabilities CAPABILITY_IAM \
		--stack-name cfn-secret-provider \
		--template-body file://cloudformation/cfn-resource-provider.yaml
	aws cloudformation wait stack-create-complete  --stack-name cfn-secret-provider

delete-secret-generator:
	aws cloudformation delete-stack --stack-name cfn-secret-provider
