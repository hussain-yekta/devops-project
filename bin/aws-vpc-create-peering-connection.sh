#!/bin/bash
set -ex
requestVpcId=$1
acceptVpcId=$2
filepath=$3
filename=$(basename $filepath)

function create-routes {
	vpcId=$1
	cidrBlock=$2
	connectionId=$3
	# Iterate over route tables and add routes
	for routeTableId in $(aws ec2 describe-route-tables --output text \
		--filters "Name=vpc-id,Values=$vpcId" \
		--query "RouteTables[].RouteTableId")
	do
		set +e
		aws ec2 create-route \
			--route-table-id $routeTableId \
			--destination-cidr-block $cidrBlock \
			--vpc-peering-connection-id $connectionId
		set -e
	done;
}

# Create the peering connection
stack=${filename%.yaml}-peering;
echo $stack
set +e
aws cloudformation create-stack \
	--capabilities CAPABILITY_IAM \
	--stack-name $stack \
	--template-body file://$filepath \
	--parameters ParameterKey=RequestingVpcId,ParameterValue=$requestVpcId \
	 	ParameterKey=AcceptingVpcId,ParameterValue=$acceptVpcId
aws cloudformation wait stack-create-complete --stack-name $stack
set -e
# Get the vpc peering connection details
connection=$(\
	aws ec2 describe-vpc-peering-connections --output json \
	--filters "Name=status-code,Values=active" \
		"Name=tag:Name,Values=$stack" \
	--query "VpcPeeringConnections[] \
		.{ \
			connectionId:VpcPeeringConnectionId, \
			RequesterVpcId:RequesterVpcInfo.VpcId \
			RequesterCidr:RequesterVpcInfo.CidrBlock \
			AccepterVpcId:AccepterVpcInfo.VpcId \
			AccepterCidr:AccepterVpcInfo.CidrBlock \
		} []"  \
	)
echo $connection
# Set the requester DNS resolution
aws ec2 modify-vpc-peering-connection-options \
	--vpc-peering-connection-id $(echo $connection | jq -r '.[0].connectionId') \
	--requester-peering-connection-options AllowDnsResolutionFromRemoteVpc=true
# Create the requester routes
create-routes \
	$(echo $connection | jq -r '.[0].RequesterVpcId') \
 	$(echo $connection | jq -r '.[0].AccepterCidr') \
	$(echo $connection | jq -r '.[0].connectionId')
# Set the accepter DNS resolution
aws ec2 modify-vpc-peering-connection-options \
	--vpc-peering-connection-id $(echo $connection | jq -r '.[0].connectionId') \
	--accepter-peering-connection-options AllowDnsResolutionFromRemoteVpc=true
# Create routes for the accepter
create-routes \
	$(echo $connection | jq -r '.[0].AccepterVpcId') \
 	$(echo $connection | jq -r '.[0].RequesterCidr') \
	$(echo $connection | jq -r '.[0].connectionId')
exit 0
