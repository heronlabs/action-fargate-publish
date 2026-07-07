#!/usr/bin/env bats

setup() {
  unset CLUSTER_NAME SERVICE_NAME
  SCRIPT="$BATS_TEST_DIRNAME/../core/publish.sh"
}

# Run the action script with the aws stub on PATH.
# Exports env assignments in $@ as if passed before the command.
# After this, $status, $output, and $aws_log are set for assertions.
run_action() {
  aws_log="$BATS_TEST_TMPDIR/aws.log"
  : >"$aws_log"
  PATH="$BATS_TEST_DIRNAME/__mocks__:$PATH" AWS_LOG="$aws_log" run env "$@" bash "$SCRIPT"
}

@test "happy: exit 0 (green)" {
  run_action CLUSTER_NAME=my-cluster SERVICE_NAME=my-svc
  [ "$status" -eq 0 ]
}

@test "happy: ecs update-service invoked" {
  run_action CLUSTER_NAME=my-cluster SERVICE_NAME=my-svc
  grep -q 'ecs update-service' "$aws_log"
}

@test "happy: --cluster my-cluster passed" {
  run_action CLUSTER_NAME=my-cluster SERVICE_NAME=my-svc
  grep -q -- '--cluster my-cluster' "$aws_log"
}

@test "happy: --service my-svc passed" {
  run_action CLUSTER_NAME=my-cluster SERVICE_NAME=my-svc
  grep -q -- '--service my-svc' "$aws_log"
}

@test "happy: --force-new-deployment passed" {
  run_action CLUSTER_NAME=my-cluster SERVICE_NAME=my-svc
  grep -q -- '--force-new-deployment' "$aws_log"
}

@test "missing cluster: hard error (non-zero)" {
  run_action SERVICE_NAME=my-svc
  [ "$status" -ne 0 ]
}

@test "missing cluster: aws NOT invoked" {
  run_action SERVICE_NAME=my-svc
  [ ! -s "$aws_log" ]
}

@test "missing service: hard error (non-zero)" {
  run_action CLUSTER_NAME=my-cluster
  [ "$status" -ne 0 ]
}

@test "missing service: aws NOT invoked" {
  run_action CLUSTER_NAME=my-cluster
  [ ! -s "$aws_log" ]
}
