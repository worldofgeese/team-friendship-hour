# Team Friendship Hour - AWS ECS Deployment

## Deployment Summary

Successfully deployed Team Friendship Hour to AWS ECS Fargate with S3 persistence.

### AWS Resources Created

1. **ECR Repository**
   - Name: `team-friendship-hour`
   - URI: `283770098737.dkr.ecr.eu-north-1.amazonaws.com/team-friendship-hour`
   - Region: `eu-north-1`

2. **S3 Bucket**
   - Name: `team-friendship-hour-data-eu-north-1`
   - Region: `eu-north-1`
   - Purpose: Persistent state storage

3. **IAM Roles**
   - `ecsTaskExecutionRole`: For ECS to pull images and write logs
   - `ecsInfrastructureRoleForExpressServices`: For ECS infrastructure management
   - `tfhTaskRole`: Runtime role with S3 access (GetObject, PutObject)

4. **ECS Resources**
   - Cluster: `team-friendship-hour`
   - Service: `team-friendship-hour`
   - Task Definition: `team-friendship-hour:1`
   - Launch Type: Fargate
   - CPU: 256
   - Memory: 512 MB

5. **Networking**
   - VPC: Default VPC (`vpc-01162eea65afcfc5b`)
   - Security Group: `sg-07816e2a580a08907`
   - Ingress: Port 8080 from 0.0.0.0/0
   - Public IP: Enabled

### Service URL

**Public Endpoint:** http://51.20.105.236:8080

Test endpoints:
- Health check: `http://51.20.105.236:8080/`
- State: `http://51.20.105.236:8080/api/state`
- Members: `http://51.20.105.236:8080/api/members`

### Code Changes

1. **Containerfile**
   - Added `aws-cli` package to Alpine image

2. **src/data/store.nu**
   - Modified `load-state` to check for `S3_BUCKET` env var
   - If set, downloads state from S3 (`s3://BUCKET/state.json`)
   - Falls back to local file storage if `S3_BUCKET` not set
   - Modified `save-state` to upload to S3 when `S3_BUCKET` is set
   - Maintains backward compatibility with local file storage

### Environment Variables

The container runs with:
- `S3_BUCKET=team-friendship-hour-data-eu-north-1`
- IAM role provides AWS credentials automatically (no hardcoded keys)

### Verification

✅ Container built and pushed to ECR  
✅ ECS service running with 1 task  
✅ Application responding to HTTP requests  
✅ S3 persistence confirmed (state.json created in bucket)  
✅ Code committed and pushed to repository  
✅ Forgesync triggered

### Container Image

- Tag: `latest`
- Digest: `sha256:b6ff11554128fcf39c50ac0eccecf9d63a710ae9e2c23a4464729f41366ca21e`
- Size: ~196 MB (Alpine + Nushell + aws-cli + http-nu)

### Notes

- Express Mode was not available in AWS CLI v1.42.18, so used standard ECS Fargate deployment
- Task role (`tfhTaskRole`) grants S3 access at runtime via IAM
- Public IP assignment enabled for direct access without load balancer
- Health check configured via Dockerfile (curl to localhost:8080 every 30s)
- CloudWatch logs enabled at `/ecs/team-friendship-hour`

### Future Improvements

1. Add Application Load Balancer for HTTPS and custom domain
2. Enable ECS Service Auto Scaling
3. Add CloudWatch alarms for monitoring
4. Configure S3 versioning for state file
5. Use Systems Manager Parameter Store for sensitive config
6. Implement blue/green deployment strategy
