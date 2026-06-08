# Publish Fargate Action

A GitHub Action that forces a rolling redeployment of an existing ECS Fargate service via `aws ecs update-service --force-new-deployment`. Use it after pushing a new image to ECR so the service picks up the latest `:latest` (or whichever tag the task definition references).

It authenticates to AWS via OIDC — no long-lived access keys.

## Requirements

### Permissions

```yaml
permissions:
  id-token: write
  contents: read
```

### AWS IAM Role

The assumed role must allow updating the target service:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "ecs:UpdateService",
      "Resource": "arn:aws:ecs:<region>:<account-id>:service/<cluster-name>/<service-name>"
    }
  ]
}
```

### Supported Runners

- `ubuntu-24.04` (recommended)
- `ubuntu-22.04`
- `ubuntu-latest`

### Dependencies

- `aws` CLI (pre-installed on GitHub-hosted runners)
- Internal: `aws-actions/configure-aws-credentials@v6`

## Inputs

| Name | Description | Required | Default |
|------|-------------|----------|---------|
| `AWS_ROLE_TO_ASSUME` | ARN of the IAM role to assume via OIDC | Yes | — |
| `AWS_REGION` | AWS region where the ECS cluster lives | Yes | — |
| `AWS_ROLE_DURATION_SECONDS` | Duration in seconds for the assumed role session | Yes | — |
| `CLUSTER_NAME` | Name of the ECS cluster hosting the service | Yes | — |
| `SERVICE_NAME` | Name of the ECS service to redeploy | Yes | — |

## Outputs

This action does not produce outputs.

## Usage

```yaml
name: Deploy to Fargate

on:
  push:
    branches: [main]

permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v6

      - name: Rolling deploy
        uses: heronlabs/action-fargate-publish@v1
        with:
          AWS_ROLE_TO_ASSUME: ${{ secrets.AWS_ROLE_ARN }}
          AWS_REGION: us-east-1
          AWS_ROLE_DURATION_SECONDS: 900
          CLUSTER_NAME: my-cluster
          SERVICE_NAME: my-service
```

## Notes

- **Image tag is not updated**: the action only triggers a redeployment of the current task definition. Update the task definition separately if you need to point it at a new tag.

## License

MIT
