# shared Makefile parameters and functions for include
PROJECT_TAG=playground
VPC_STACK_NAME=playground-vpc
BASTION_STACK_NAME=playground-bastion
DB_STACK_NAME=playground-database-beta
CONTAINER_STACK_NAME=playground-container
CONTAINER_NAME=fortune
ECR_REPOSITORY_NAME=playground-repo
KEY_PAIR=macbook2018
PROPERTIES_FILE=../config/properties.mk.gitignore
DB_ENDPOINT_PARAMETER_NAME="/beta/database/playground/endpoint"
DB_SECRET_NAME="/beta/database/playground/secret"
EDGE_BUCKET_NAME=sandbox00-fortune
EDGE_STACK_NAME=playground-edge

dump:
	@echo Parameters:
	@cat $(PROPERTIES_FILE)

init:
	# Set updated parameters into properties file.
	# the generated file can be included from Makefile, or sourced in a Bash shell.
	@echo "# Dynamically generated properties file." > $(PROPERTIES_FILE)
	@echo "export VPC_ID="`aws cloudformation describe-stack-resources \
				--stack-name ${VPC_STACK_NAME} --logical-resource-id VPC \
				| jq -r '.StackResources[0].PhysicalResourceId'` >> $(PROPERTIES_FILE)
	@echo "export PUBLIC_SUBNET1="`aws cloudformation describe-stack-resources \
				--stack-name ${VPC_STACK_NAME} --logical-resource-id PublicSubnet1 \
				| jq -r '.StackResources[0].PhysicalResourceId'` >> $(PROPERTIES_FILE)
	@echo "export PUBLIC_SUBNET2="`aws cloudformation describe-stack-resources \
				--stack-name ${VPC_STACK_NAME} --logical-resource-id PublicSubnet2 \
				| jq -r '.StackResources[0].PhysicalResourceId'` >> $(PROPERTIES_FILE)
	@echo "export PRIVATE_SUBNET1="`aws cloudformation describe-stack-resources \
				--stack-name ${VPC_STACK_NAME} --logical-resource-id PrivateSubnet1 \
				| jq -r '.StackResources[0].PhysicalResourceId'` >> $(PROPERTIES_FILE)
	@echo "export PRIVATE_SUBNET2="`aws cloudformation describe-stack-resources \
				--stack-name ${VPC_STACK_NAME} --logical-resource-id PrivateSubnet2 \
				| jq -r '.StackResources[0].PhysicalResourceId'` >> $(PROPERTIES_FILE)
	@echo "export AZ1="`aws ec2 describe-subnets --subnet-ids ${PRIVATE_SUBNET1} \
				| jq -r '.Subnets[0].AvailabilityZone'` >> $(PROPERTIES_FILE)
	@echo "export AZ2="`aws ec2 describe-subnets --subnet-ids ${PRIVATE_SUBNET2} \
				| jq -r '.Subnets[0].AvailabilityZone'` >> ${PROPERTIES_FILE}
	@echo "export DMZ_SECURITY_GROUP="`aws cloudformation describe-stacks --stack-name $(VPC_STACK_NAME) \
			| jq -r '.Stacks[0].Outputs[] | select(.OutputKey == "DmzSecurityGroup") | .OutputValue'` >> $(PROPERTIES_FILE)
	@echo "export APP_SECURITY_GROUP="`aws cloudformation describe-stacks --stack-name $(VPC_STACK_NAME) \
			| jq -r '.Stacks[0].Outputs[] | select(.OutputKey == "AppSecurityGroup") | .OutputValue'` >> $(PROPERTIES_FILE)
	@echo "export DB_SECURITY_GROUP="`aws cloudformation describe-stacks --stack-name $(VPC_STACK_NAME) \
			| jq -r '.Stacks[0].Outputs[] | select(.OutputKey == "DbSecurityGroup") | .OutputValue'` >> $(PROPERTIES_FILE)
	@echo "export BASTION_IP="`aws cloudformation describe-stacks --stack-name $(BASTION_STACK_NAME) \
			| jq -r '.Stacks[0].Outputs[] | select(.OutputKey == "PublicIP") | .OutputValue'` >> $(PROPERTIES_FILE)
	@echo "export BASTION_INSTANCE="`aws cloudformation describe-stacks --stack-name $(BASTION_STACK_NAME) \
			| jq -r '.Stacks[0].Outputs[] | select(.OutputKey == "InstanceId") | .OutputValue'` >> $(PROPERTIES_FILE)
	@echo "export DB_HOST="`aws ssm get-parameter --name ${DB_ENDPOINT_PARAMETER_NAME} \
		| jq -r '.Parameter.Value'` >> $(PROPERTIES_FILE)
	@echo "export ECR_REPOSITORY_URI="`aws ecr describe-repositories --repository-names ${ECR_REPOSITORY_NAME} \
				| jq -r '.repositories[0].repositoryUri'`  >> $(PROPERTIES_FILE)
	@cat $(PROPERTIES_FILE)

config-db-secret:
	$(eval DB_PASSWORD  = $(shell aws secretsmanager get-secret-value --secret-id ${DB_SECRET_NAME} \
					| jq -r '.SecretString' | jq -r '.password'))
