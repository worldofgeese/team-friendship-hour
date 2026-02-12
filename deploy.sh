#!/usr/bin/env bash
# Deploy Team Friendship Hour to AWS ECS via SST
# Usage: ./deploy.sh [stage] [tag]
#   stage: SST stage name (default: production)
#   tag:   Docker image tag (default: latest)
#
# Prerequisites:
#   - AWS credentials configured (aws configure or env vars)
#   - Docker or Podman running
#   - bun/npm install done (for SST)
set -euo pipefail

STAGE="${1:-production}"
TAG="${2:-latest}"
REGION="${AWS_DEFAULT_REGION:-eu-north-1}"
REPO_NAME="team-friendship-hour"

echo "==> Resolving AWS account..."
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
ECR="$ACCOUNT.dkr.ecr.$REGION.amazonaws.com"

echo "==> Ensuring ECR repository exists..."
aws ecr describe-repositories --repository-names "$REPO_NAME" --region "$REGION" >/dev/null 2>&1 \
  || aws ecr create-repository --repository-name "$REPO_NAME" --region "$REGION" --query 'repository.repositoryUri' --output text

echo "==> Logging in to ECR..."
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$ECR"

echo "==> Building image..."
# DOCKER_BUILDKIT=0 for Podman compatibility; remove if using Docker with BuildKit
DOCKER_BUILDKIT=0 docker build -f Containerfile -t "$ECR/$REPO_NAME:$TAG" .

echo "==> Pushing image..."
docker push "$ECR/$REPO_NAME:$TAG"

echo "==> Deploying with SST (stage: $STAGE)..."
npx sst deploy --stage "$STAGE"

echo "==> Done!"
