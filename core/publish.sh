#!/usr/bin/env bash

set -euo pipefail

: "${CLUSTER_NAME:?CLUSTER_NAME is required}"
: "${SERVICE_NAME:?SERVICE_NAME is required}"

aws ecs update-service \
  --cluster "${CLUSTER_NAME}" \
  --service "${SERVICE_NAME}" \
  --force-new-deployment
