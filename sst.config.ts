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
    // S3 bucket for persistent state
    const bucket = new sst.aws.Bucket("TfhState");

    // VPC + Cluster
    const vpc = new sst.aws.Vpc("TfhVpc");
    const cluster = new sst.aws.Cluster("TfhCluster", { vpc });

    // Service with Cloud Map for service discovery
    const service = new sst.aws.Service("TeamFriendshipHour", {
      cluster,
      // Pre-built image (SST can't use BuildKit with podman-in-podman)
      // To rebuild: DOCKER_BUILDKIT=0 DOCKER_API_VERSION=1.41 docker build -f Containerfile -t 283770098737.dkr.ecr.eu-north-1.amazonaws.com/team-friendship-hour:latest .
      // Then push: DOCKER_API_VERSION=1.41 docker push 283770098737.dkr.ecr.eu-north-1.amazonaws.com/team-friendship-hour:latest
      image: "283770098737.dkr.ecr.eu-north-1.amazonaws.com/team-friendship-hour:latest",
      environment: {
        S3_BUCKET: bucket.name
      },
      link: [bucket],
      serviceRegistry: {
        port: 8080
      },
      capacity: "spot",  // ~$6/mo instead of $12
    });

    // API Gateway for public access (no ALB needed, pay-per-request)
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
