/// <reference path="./.sst/platform/config.d.ts" />

export default $config({
  app(input) {
    return {
      name: "team-friendship-hour",
      removal: input?.stage === "production" ? "retain" : "remove",
      home: "aws",
      providers: {
        aws: {
          region: "eu-north-1"
        }
      }
    };
  },
  async run() {
    // Resolve account + region dynamically
    const account = aws.getCallerIdentityOutput().accountId;
    const region = aws.getRegionOutput().name;

    // S3 bucket for persistent state
    const bucket = new sst.aws.Bucket("TfhState");

    // VPC + Cluster
    const vpc = new sst.aws.Vpc("TfhVpc");
    const cluster = new sst.aws.Cluster("TfhCluster", { vpc });

    // Pre-built image from ECR (built and pushed by deploy.sh)
    const image = $interpolate`${account}.dkr.ecr.${region}.amazonaws.com/team-friendship-hour:latest`;

    // ECS Fargate service
    const service = new sst.aws.Service("TeamFriendshipHour", {
      cluster,
      image,
      environment: {
        S3_BUCKET: bucket.name
      },
      link: [bucket],
      serviceRegistry: {
        port: 8080
      },
      capacity: "spot",  // ~$6/mo instead of ~$12
    });

    // API Gateway for public access (pay-per-request, no ALB needed)
    const api = new sst.aws.ApiGatewayV2("TfhApi", {
      vpc
    });
    api.routePrivate("$default", service.nodes.cloudmapService.arn);

    return {
      api: api.url,
      bucket: bucket.name
    };
  }
});
