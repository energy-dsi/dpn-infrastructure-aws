#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT="${1:-}"
ACTION="${2:-}"

if [[ -z "$ENVIRONMENT" || -z "$ACTION" ]]; then
  echo "Usage: ./scripts/deploy.sh <dev|test> <init|plan|apply|validate|fmt>"
  exit 1
fi

case "$ENVIRONMENT" in
  dev)
    export AWS_PROFILE="dpn-dev"
    BACKEND="backends/dev.hcl"
    VAR_FILE="environments/dev.tfvars"
    PLAN_FILE="dev.plan"
    ;;
  test)
    export AWS_PROFILE="dpn-test"
    BACKEND="backends/test.hcl"
    VAR_FILE="environments/test.tfvars"
    PLAN_FILE="test.plan"
    ;;
  *)
    echo "Invalid environment: $ENVIRONMENT. Use dev or test."
    exit 1
    ;;
esac

echo "Environment : $ENVIRONMENT"
echo "AWS_PROFILE : $AWS_PROFILE"

if ! aws sts get-caller-identity --profile "$AWS_PROFILE" >/dev/null 2>&1; then
  echo "SSO session expired or missing. Running aws sso login..."
  aws sso login --profile "$AWS_PROFILE"
fi

aws sts get-caller-identity --profile "$AWS_PROFILE"

case "$ACTION" in
  init)
    tofu init -reconfigure -backend-config="$BACKEND"
    ;;
  fmt)
    tofu fmt -recursive
    ;;
  validate)
    tofu validate
    ;;
  plan)
    tofu init -reconfigure -backend-config="$BACKEND"
    tofu plan -var-file="$VAR_FILE" -out="$PLAN_FILE"
    ;;
  apply)
    tofu apply "$PLAN_FILE"
    ;;
  *)
    echo "Invalid action: $ACTION"
    echo "Allowed: init, fmt, validate, plan, apply"
    exit 1
    ;;
esac
