# Deployment

Team Friendship Hour deploys to AWS ECS Fargate via [SST](https://sst.dev) (v3).

## Architecture

```
Internet → API Gateway → VPC Link → ECS Service (Fargate Spot)
                                        ↓
                                    S3 Bucket (state persistence)
```

SST manages: VPC, ECS Cluster, Fargate Service, S3 bucket, IAM roles, API Gateway, and auto-scaling.

## Prerequisites

- [Node.js](https://nodejs.org/) or [Bun](https://bun.sh/)
- [Docker](https://docs.docker.com/get-docker/) (or Podman with `DOCKER_BUILDKIT=0`)
- AWS credentials configured (`aws configure` or environment variables)
- An [ECR repository](https://aws.amazon.com/ecr/) for container images

## Setup

```bash
# Install dependencies (includes SST)
bun install

# Create ECR repo (first time only)
aws ecr create-repository --repository-name team-friendship-hour --region eu-north-1
```

## Deploy

### 1. Build and push the container image

SST expects a pre-built image in ECR. Build and push before deploying:

```bash
# Set your account ID and region
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_REGION=eu-north-1
export ECR_URI=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/team-friendship-hour

# Login to ECR
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Build and push
docker build -f Containerfile -t $ECR_URI:latest .
docker push $ECR_URI:latest
```

> **Podman users:** Prefix build with `DOCKER_BUILDKIT=0` — BuildKit doesn't work in rootless Podman.

### 2. Update the image reference in `sst.config.ts`

The `image` field in the Service config must match your ECR URI:

```ts
image: "<your-account-id>.dkr.ecr.eu-north-1.amazonaws.com/team-friendship-hour:latest",
```

### 3. Deploy with SST

```bash
# Deploy to production
npx sst deploy --stage production

# Deploy to a dev/test stage
npx sst deploy --stage dev
```

SST outputs the API Gateway URL on completion.

## Tear Down

```bash
npx sst remove --stage production
```

This removes all AWS resources created by SST (VPC, cluster, service, S3 bucket, API Gateway, IAM roles).

> **Note:** `sst remove` can take several minutes due to VPC Link and CloudMap namespace deletion. Let it finish — killing it mid-run leaves orphaned resources.

After removal, optionally clean up:
```bash
# Delete ECR repo
aws ecr delete-repository --repository-name team-friendship-hour --force

# Delete SST bootstrap (if you want a fully clean account)
aws ssm delete-parameter --name /sst/bootstrap
aws s3 rb s3://$(aws ssm get-parameter --name /sst/bootstrap --query 'Parameter.Value' --output text | jq -r '.state') --force
aws s3 rb s3://$(aws ssm get-parameter --name /sst/bootstrap --query 'Parameter.Value' --output text | jq -r '.asset') --force
```

## Cost

Fargate Spot (default): **~$6/month**
- 0.25 vCPU, 0.5 GB RAM
- Public IPv4 address
- API Gateway (pay-per-request, negligible for low traffic)
- S3 (negligible for small state files)

Fargate on-demand: ~$12/month. Change `capacity` in `sst.config.ts`.

## Local Development

```bash
# Run with Docker Compose
docker compose up --build

# Access at http://localhost:8080
```

State is stored in a named volume (`data:/app/data`) locally, or S3 when `S3_BUCKET` is set.
