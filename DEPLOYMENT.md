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

- [Bun](https://bun.sh/) or [Node.js](https://nodejs.org/)
- [Docker](https://docs.docker.com/get-docker/) (or Podman)
- AWS credentials configured (`aws configure` or environment variables)

## Quick Start

```bash
# Install dependencies
bun install

# Deploy (builds image, pushes to ECR, deploys infrastructure)
./deploy.sh
```

That's it. The script handles ECR repo creation, image build+push, and SST deployment. On completion it prints the live API Gateway URL.

## Scripts

### `deploy.sh [stage] [tag]`

One-command deploy. Defaults to `production` stage and `latest` tag.

```bash
./deploy.sh                    # Deploy to production
./deploy.sh dev                # Deploy to a dev stage
./deploy.sh production v1.2.0  # Deploy with a specific image tag
```

What it does:
1. Logs in to ECR
2. Builds the container image
3. Pushes to ECR (repo auto-created on first push)
4. Runs `sst deploy`

### `teardown.sh [stage]`

Removes all AWS resources created by SST and cleans up the ECR repository.

```bash
./teardown.sh              # Tear down production
./teardown.sh dev          # Tear down dev stage
```

> **Note:** `sst remove` can take a few minutes (VPC and CloudMap cleanup). Let it finish — killing it mid-run can leave orphaned resources.

## Manual Deploy

If you prefer running steps individually:

```bash
# Set variables
export AWS_DEFAULT_REGION=eu-north-1
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
ECR="$ACCOUNT.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com"

# Build and push (ECR repo auto-created on first push)
aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $ECR
docker build -f Containerfile -t $ECR/team-friendship-hour:latest .
docker push $ECR/team-friendship-hour:latest

# Deploy
npx sst deploy --stage production
```

> **Podman users:** Prefix build with `DOCKER_BUILDKIT=0` — BuildKit doesn't work in rootless Podman.

## Configuration

Edit `sst.config.ts` to adjust:

- **`capacity`** — `"spot"` (~$6/mo) or remove for on-demand (~$12/mo)
- **`removal`** — `"retain"` (production) keeps S3 bucket on teardown; `"remove"` (other stages) deletes everything
- **Region** — Change in both `providers.aws.region` and `AWS_DEFAULT_REGION`

The account ID and ECR URI are resolved dynamically — no hardcoded values.

## Cost

Fargate Spot (default): **~$6/month**
- 0.25 vCPU, 0.5 GB RAM
- API Gateway (pay-per-request, negligible at low traffic)
- S3 (negligible for small state files)

Fargate on-demand: ~$12/month.

## Local Development

```bash
docker compose up --build
# Access at http://localhost:8080
```

State is stored in a named volume locally, or S3 when `S3_BUCKET` is set.
