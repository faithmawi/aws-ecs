# ECS/Fargate demo
The goal of this demo is to deploy the [high-scores app](https://github.com/infinityworks/academy-high-scores) to AWS ECS on Fargate. Pre-reqs are that the high-scores app containers have been built and pushed into ECR.

# IAM role

Create a role to execute ecs tasks:

```sh
aws iam --region eu-west-2 create-role --role-name ecsTaskExecutionRole --assume-role-policy-document file://task-execution-assume-role.json

aws iam --region eu-west-2 attach-role-policy --role-name ecsTaskExecutionRole --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
```

# Cluster creation

Create a fargate cluster (jump over to console to show each step once completed).

These commands will spit out a VPC and subnet IDs, make a note as it's needed to get the security groups.

```sh
ecs-cli configure --cluster academy-2020-fargate --default-launch-type FARGATE --config-name academy-2020-fargate-config --region eu-west-2

ecs-cli configure profile --access-key <access_key_id> --secret-key <secret_key> --profile-name ecs-profile

ecs-cli up --cluster-config academy-2020-fargate-config --ecs-profile ecs-profile
```

# Ingress rules
Fetch the security groups (replace the VPC ID value with the one provided by the command above)
Make a note of the security group ID listed here:

```sh
aws ec2 describe-security-groups --filters Name=vpc-id,Values=vpc-09bfa8ad9db8a7cef --region eu-west-2
```

Run these commands for the security group ID retrieved above (the CIDR here allows access from the IW VPN only).

```sh
aws ec2 authorize-security-group-ingress --group-id sg-0aaa2df6998c74d3f --protocol tcp --port 80 --cidr 52.51.7.138/32 --region eu-west-2
aws ec2 authorize-security-group-ingress --group-id sg-0aaa2df6998c74d3f --protocol tcp --port 8080 --cidr 52.51.7.138/32 --region eu-west-2
aws ec2 authorize-security-group-ingress --group-id sg-0aaa2df6998c74d3f --protocol tcp --port 8000 --cidr 52.51.7.138/32 --region eu-west-2
```

# Deploy service

Update the `ecs-params.yml` file with the security group ID and subnet IDs retrieved above. Can run through the configuration in that file at this point.

Run through the `docker-compose.yml` and explain the parameters being used. Referencing back to the port numbers used in the ingress rules can be helpful, also mentioning the logging section as this will be new.

Deploy the service to the fargate cluster:

```sh
ecs-cli compose --project-name academy-2020-high-scores service up --create-log-groups --cluster-config academy-2020-fargate-config --ecs-profile ecs-profile
```

List the services running on the fargate cluster, you can also view this in the console:

```sh
ecs-cli compose --project-name academy-2020-high-scores service ps --cluster-config academy-2020-fargate-config --ecs-profile ecs-profile
```

# Cleanup

```sh
ecs-cli compose --project-name academy-2020-high-scores service down --cluster-config academy-2020-fargate-config --ecs-profile ecs-profile
ecs-cli down --force --cluster-config academy-2020-fargate-config --ecs-profile ecs-profile
```
