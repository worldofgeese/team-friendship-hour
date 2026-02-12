#!/usr/bin/env bash
# Tear down all AWS resources for Team Friendship Hour
# Usage: ./teardown.sh [stage]
set -euo pipefail

STAGE="${1:-production}"
REGION="${AWS_DEFAULT_REGION:-eu-north-1}"
REPO_NAME="team-friendship-hour"

echo "==> Removing SST stack (stage: $STAGE)..."
npx sst remove --stage "$STAGE"

echo "==> Cleaning up ECR repository..."
aws ecr delete-repository --repository-name "$REPO_NAME" --force --region "$REGION" 2>/dev/null \
  && echo "    ECR repo deleted" \
  || echo "    ECR repo not found (already deleted)"

echo "==> Done! All resources removed."
echo ""
echo "Optional: remove SST bootstrap resources (shared across all SST apps):"
echo "  aws ssm delete-parameter --name /sst/bootstrap"
echo "  # Then delete the sst-state-* and sst-asset-* S3 buckets manually"
