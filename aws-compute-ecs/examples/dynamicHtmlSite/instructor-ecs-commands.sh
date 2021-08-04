#!/bin/sh

# Get the `examples.zip` from this session, download and Unzip
# Do all these commands in that folder

# User specific
export ECS_MY_REPO_NAME=nja-markm-pokemon-app

# Common
export ECS_TEAM_NAME=nja-team-jan-2021
export ECS_ACADEMY_VPC_ID=vpc-0ea2360d748771bc9
export ECS_ACADEMY_SG_ID=sg-046b9e840ad94e0a7
export ECS_ACADEMY_SG_NAME=nja-team-jan-2021-vpn-only
export ECS_ACADEMY_SUBNET_A_ID=subnet-0092335aa0710ef64
export ECS_ACADEMY_SUBNET_B_ID=subnet-0c58c036609272ba9
export ECS_ACADEMY_SUBNET_C_ID=subnet-00fb8edb4f4c86f38
export ECS_ACADEMY_SUBNETS=${ECS_ACADEMY_SUBNET_A_ID},${ECS_ACADEMY_SUBNET_B_ID},${ECS_ACADEMY_SUBNET_C_ID}

# Run local, browse, turn off
docker-compose --file docker-compose-local.yml up --build -d
# -> browse to http://localhost:3000
docker-compose --file docker-compose-local.yml down
# Or we could just build the image
docker-compose --file docker-compose-local.yml build 

# Tag image
docker tag pokemon-dynamic-app:latest \
    ${AWS_ACCOUNT}.dkr.ecr.eu-west-1.amazonaws.com/${ECS_MY_REPO_NAME}:latest

# Docker repo login
aws ecr get-login-password --region eu-west-1 \
   --profile iw-academy \
   | docker login --username AWS --password-stdin \
    ${AWS_ACCOUNT}.dkr.ecr.eu-west-1.amazonaws.com

# Push your image up
docker push \
    ${AWS_ACCOUNT}.dkr.ecr.eu-west-1.amazonaws.com/${ECS_MY_REPO_NAME}:latest

# Make role
# Only the instructor has permissions to do this
aws iam --region eu-west-1 create-role \
  --role-name ${ECS_TEAM_NAME}-ecsTaskExecutionRole \
  --assume-role-policy-document \
  file://task-execution-assume-role.json \
  --profile iw-academy

# Attach a Role-Policy
# Only the instructor has permissions to do this
aws iam --region eu-west-1 attach-role-policy \
  --role-name ${ECS_TEAM_NAME}-ecsTaskExecutionRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy \
  --profile iw-academy

# Configure local cluster deinition
# Everyone has permissions to do this
ecs-cli configure --cluster ${ECS_TEAM_NAME}-cluster \
  --default-launch-type FARGATE \
  --config-name ${ECS_TEAM_NAME}-cluster-config \
  --region eu-west-1
 
# Configure AWS credentials
# Everyone has permissions to do this
# If your AWS creds expire (=1hr only) you must get new ones and do this again
ecs-cli configure profile \
  --profile-name ${ECS_TEAM_NAME}-ecs-profile

# Confirm security group is right - should find it and show us the name
aws ec2 describe-security-groups \
  --query 'SecurityGroups[*]' \
  --region eu-west-1 --profile=nja-instructor \
  | grep ${ECS_ACADEMY_SG_NAME}

# Instructor - Start the cluster
# Do this once per Team (or Cohort)
# Everyone has permissions to do this
ecs-cli up --cluster-config ${ECS_TEAM_NAME}-cluster-config \
  --ecs-profile ${ECS_TEAM_NAME}-ecs-profile \
  --instance-role ${ECS_TEAM_NAME}-ecsTaskExecutionRole \
  --vpc ${ECS_ACADEMY_VPC_ID} \
  --subnets ${ECS_ACADEMY_SUBNETS} \
  --security-group ${ECS_ACADEMY_SG_ID}

# Start individual services
# Everyone has permissions to do this
ecs-cli compose \
  --file docker-compose-ecs.yml \
  --project-name ${ECS_MY_REPO_NAME} \
  --ecs-params ecs-params.yml \
  service up \
  --create-log-groups \
  --cluster-config ${ECS_TEAM_NAME}-cluster-config \
  --cluster ${ECS_TEAM_NAME}-cluster \
  --ecs-profile ${ECS_TEAM_NAME}-ecs-profile

# List individual services running
# Everyone has permissions to do this
ecs-cli compose \
  --file docker-compose-ecs.yml \
  --project-name ${ECS_MY_REPO_NAME} \
  service ps \
  --cluster-config ${ECS_TEAM_NAME}-cluster-config \
  --ecs-profile ${ECS_TEAM_NAME}-ecs-profile

exit 1
# ^^ means an Instructor can run this script up to here and you should see working results :-) 
# ..and then shut down after

# Shut your service down
ecs-cli compose --project-name ${ECS_MY_REPO_NAME}-project \
  service down \
  --cluster-config ${ECS_TEAM_NAME}-cluster-config \
  --ecs-profile ${ECS_TEAM_NAME}-ecs-profile

# Teardown the cluster
ecs-cli down --force \
   --cluster-config ${ECS_TEAM_NAME}-cluster-config \
   --ecs-profile ${ECS_TEAM_NAME}-ecs-profile
