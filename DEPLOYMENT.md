# Team Friendship Hour — ECS Deployment Guide

## Overview

Team Friendship Hour is a Nushell web app served by [http-nu](https://github.com/cablehead/http-nu). It deploys to AWS ECS Fargate with S3-backed persistence.

## Prerequisites

- AWS CLI v2 installed
- AWS credentials configured (see "Credentials" below)
- Docker or Podman for building the image

## Credentials

AWS credentials are stored in agenix on Paphos:

```bash
# From OpenClaw container:
ssh -i ~/.ssh/id_ed25519_paphos kypris@192.168.99.104 "sudo cat /run/agenix/aws-access-key-id"
ssh -i ~/.ssh/id_ed25519_paphos kypris@192.168.99.104 "sudo cat /run/agenix/aws-secret-access-key"

# Configure:
export AWS_ACCESS_KEY_ID=$(ssh -i ~/.ssh/id_ed25519_paphos kypris@192.168.99.104 "sudo cat /run/agenix/aws-access-key-id")
export AWS_SECRET_ACCESS_KEY=$(ssh -i ~/.ssh/id_ed25519_paphos kypris@192.168.99.104 "sudo cat /run/agenix/aws-secret-access-key")
export AWS_DEFAULT_REGION=eu-north-1
```

**Account:** 283770098737
**Region:** eu-north-1 (Stockholm)
**Purpose:** Testing/staging deployments for containerized apps

## Architecture

```
                    ┌─────────────────┐
                    │  ECS Express     │
Internet ──────────▶│  Mode Service    │
                    │  (Fargate)       │
                    │  Port 8080       │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │  S3 Bucket       │
                    │  state.json      │
                    │  (persistence)   │
                    └─────────────────┘
```

## Step-by-step Deployment

### 1. Create ECR Repository

```bash
aws ecr create-repository \
  --repository-name team-friendship-hour \
  --region eu-north-1
```

### 2. Create S3 Bucket for Persistence

```bash
aws s3 mb s3://team-friendship-hour-data-eu-north-1 --region eu-north-1
```

### 3. Build and Push Image

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_URI="${ACCOUNT_ID}.dkr.ecr.eu-north-1.amazonaws.com/team-friendship-hour"

# Login to ECR
aws ecr get-login-password --region eu-north-1 | \
  docker login --username AWS --password-stdin "${ACCOUNT_ID}.dkr.ecr.eu-north-1.amazonaws.com"

# Build
docker build -f Containerfile -t team-friendship-hour:latest .

# Tag and push
docker tag team-friendship-hour:latest "${ECR_URI}:latest"
docker push "${ECR_URI}:latest"
```

### 4. Create IAM Roles

```bash
# Task Execution Role (ECS pulls images + writes logs)
aws iam create-role --role-name ecsTaskExecutionRole \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"Service": "ecs-tasks.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }]
  }'

aws iam attach-role-policy --role-name ecsTaskExecutionRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy

# Infrastructure Role (ECS Express Mode)
aws iam create-role --role-name ecsInfrastructureRoleForExpressServices \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"Service": "ecs.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }]
  }'

aws iam attach-role-policy --role-name ecsInfrastructureRoleForExpressServices \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSInfrastructureRoleForExpressGatewayServices

# Task Role (runtime S3 access — needed for persistence)
aws iam create-role --role-name tfhTaskRole \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"Service": "ecs-tasks.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }]
  }'

aws iam put-role-policy --role-name tfhTaskRole \
  --policy-name S3Access \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject"],
      "Resource": "arn:aws:s3:::team-friendship-hour-data-eu-north-1/*"
    }]
  }'
```

### 5. Deploy with ECS Express Mode

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

aws ecs create-express-gateway-service \
  --region eu-north-1 \
  --service-name "team-friendship-hour" \
  --primary-container "{
    \"image\": \"${ACCOUNT_ID}.dkr.ecr.eu-north-1.amazonaws.com/team-friendship-hour:latest\",
    \"containerPort\": 8080,
    \"environment\": [
      {\"name\": \"S3_BUCKET\", \"value\": \"team-friendship-hour-data-eu-north-1\"},
      {\"name\": \"PORT\", \"value\": \"8080\"}
    ]
  }" \
  --execution-role-arn "arn:aws:iam::${ACCOUNT_ID}:role/ecsTaskExecutionRole" \
  --infrastructure-role-arn "arn:aws:iam::${ACCOUNT_ID}:role/ecsInfrastructureRoleForExpressServices" \
  --health-check-path "/" \
  --cpu 1 --memory 2 \
  --monitor-resources
```

**Note:** Express Mode may not support `--task-role-arn`. If so, update the task definition after creation:

```bash
# Get the task definition created by Express Mode
TASK_DEF=$(aws ecs describe-services --cluster default --services team-friendship-hour \
  --query 'services[0].taskDefinition' --output text)

# Describe it, add taskRoleArn, re-register
aws ecs describe-task-definition --task-definition "$TASK_DEF" \
  --query 'taskDefinition.{containerDefinitions:containerDefinitions,family:family,cpu:cpu,memory:memory,networkMode:networkMode,requiresCompatibilities:requiresCompatibilities,executionRoleArn:executionRoleArn}' \
  | jq '. + {"taskRoleArn": "arn:aws:iam::'$ACCOUNT_ID':role/tfhTaskRole"}' \
  > /tmp/task-def.json

aws ecs register-task-definition --cli-input-json file:///tmp/task-def.json

# Force new deployment with updated task def
aws ecs update-service --cluster default --service team-friendship-hour \
  --task-definition team-friendship-hour --force-new-deployment
```

### 6. Verify

```bash
# Get service URL (Express Mode provides one)
aws ecs describe-services --cluster default --services team-friendship-hour \
  --query 'services[0]'

# Test endpoints
curl https://<service-url>/
curl https://<service-url>/api/state
```

## Tear Down

Complete cleanup of all resources:

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# 1. Delete ECS service (force stops tasks)
aws ecs update-service --cluster default --service team-friendship-hour --desired-count 0
aws ecs delete-service --cluster default --service team-friendship-hour --force

# 2. Delete ECS cluster (if dedicated)
aws ecs delete-cluster --cluster team-friendship-hour

# 3. Deregister task definition(s)
for td in $(aws ecs list-task-definitions --family-prefix team-friendship-hour --query 'taskDefinitionArns[]' --output text); do
  aws ecs deregister-task-definition --task-definition "$td"
done

# 4. Delete ECR repository (including images)
aws ecr delete-repository --repository-name team-friendship-hour --force

# 5. Empty and delete S3 bucket
aws s3 rm s3://team-friendship-hour-data-eu-north-1 --recursive
aws s3 rb s3://team-friendship-hour-data-eu-north-1

# 6. Delete security group (wait ~60s for ENI detach)
SG_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=*team-friendship*" \
  --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null)
[ "$SG_ID" != "None" ] && aws ec2 delete-security-group --group-id "$SG_ID"

# 7. Delete IAM roles
aws iam delete-role-policy --role-name tfhTaskRole --policy-name S3Access
aws iam delete-role --role-name tfhTaskRole

aws iam detach-role-policy --role-name ecsInfrastructureRoleForExpressServices \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSInfrastructureRoleForExpressGatewayServices
aws iam delete-role --role-name ecsInfrastructureRoleForExpressServices

aws iam detach-role-policy --role-name ecsTaskExecutionRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
aws iam delete-role --role-name ecsTaskExecutionRole

# 8. Delete CloudWatch log group
aws logs delete-log-group --log-group-name /ecs/team-friendship-hour
```

## Local Development

Run locally without AWS (uses local file storage):

```bash
# Without S3 (local persistence in ./data/):
http-nu 0.0.0.0:8080 src/handler.nu

# With S3 (requires AWS credentials):
S3_BUCKET=team-friendship-hour-data-eu-north-1 http-nu 0.0.0.0:8080 src/handler.nu
```

## Storage Behavior

- If `S3_BUCKET` env var is set → reads/writes `state.json` from S3
- If not set → uses local `data/state.json` (backward compatible)
- State file is a single JSON document with members, activities, and cycle data
