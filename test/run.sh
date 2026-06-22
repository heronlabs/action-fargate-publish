#!/usr/bin/env bash
# Offline test harness for core/publish-fargate.sh.
#
# Puts an `aws` stub on PATH, runs the action script with env-injected inputs, and
# asserts on exit codes plus the recorded `aws` argv. No network, no real AWS.
#
# shellcheck disable=SC2015  # `cond && ok || bad` is intentional; ok() always returns 0
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$HERE/../core/publish-fargate.sh"
STUB_DIR="$HERE"   # contains the `aws` stub

# Never let the outer environment leak required inputs into the missing-var tests.
unset CLUSTER_NAME SERVICE_NAME

pass=0
fail=0
note() { printf '  %s\n' "$*"; }
ok()   { pass=$((pass + 1)); printf 'ok   - %s\n' "$1"; }
bad()  { fail=$((fail + 1)); printf 'FAIL - %s\n' "$1"; [ -n "${2:-}" ] && note "$2"; }

# Run the action script with the `aws` stub on PATH and a fresh log file.
# Usage: run_action [extra env assignments...]
# Exports RUN_OUT/RUN_RC/RUN_AWSLOG for the caller.
run_action() {
  RUN_AWSLOG="$(mktemp)"
  : >"$RUN_AWSLOG"
  RUN_OUT="$(
    env PATH="$STUB_DIR:$PATH" \
        AWS_LOG="$RUN_AWSLOG" \
        "$@" \
        bash "$SCRIPT" 2>&1
  )"
  RUN_RC=$?
}

# ---------------------------------------------------------------- tests

test_happy_path() {
  run_action CLUSTER_NAME=my-cluster SERVICE_NAME=my-svc

  [ "$RUN_RC" -eq 0 ] && ok "happy: exit 0 (green)" || bad "happy: exit 0 (green)" "rc=$RUN_RC out=$RUN_OUT"

  grep -q 'ecs update-service' "$RUN_AWSLOG" && ok "happy: ecs update-service invoked" || bad "happy: ecs update-service invoked" "$(cat "$RUN_AWSLOG")"
  grep -q -- '--cluster my-cluster' "$RUN_AWSLOG" && ok "happy: --cluster my-cluster passed" || bad "happy: --cluster my-cluster passed" "$(cat "$RUN_AWSLOG")"
  grep -q -- '--service my-svc' "$RUN_AWSLOG" && ok "happy: --service my-svc passed" || bad "happy: --service my-svc passed" "$(cat "$RUN_AWSLOG")"
  grep -q -- '--force-new-deployment' "$RUN_AWSLOG" && ok "happy: --force-new-deployment passed" || bad "happy: --force-new-deployment passed" "$(cat "$RUN_AWSLOG")"

  rm -rf "$RUN_AWSLOG"
}

test_missing_cluster_name() {
  run_action SERVICE_NAME=my-svc
  [ "$RUN_RC" -ne 0 ] && ok "missing cluster: hard error (non-zero)" || bad "missing cluster: hard error (non-zero)" "rc=$RUN_RC out=$RUN_OUT"
  [ ! -s "$RUN_AWSLOG" ] && ok "missing cluster: aws NOT invoked" || bad "missing cluster: aws NOT invoked" "$(cat "$RUN_AWSLOG")"
  rm -rf "$RUN_AWSLOG"
}

test_missing_service_name() {
  run_action CLUSTER_NAME=my-cluster
  [ "$RUN_RC" -ne 0 ] && ok "missing service: hard error (non-zero)" || bad "missing service: hard error (non-zero)" "rc=$RUN_RC out=$RUN_OUT"
  [ ! -s "$RUN_AWSLOG" ] && ok "missing service: aws NOT invoked" || bad "missing service: aws NOT invoked" "$(cat "$RUN_AWSLOG")"
  rm -rf "$RUN_AWSLOG"
}

# ---------------------------------------------------------------- run

test_happy_path
test_missing_cluster_name
test_missing_service_name

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
