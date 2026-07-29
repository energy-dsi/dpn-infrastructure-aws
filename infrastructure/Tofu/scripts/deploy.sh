#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT="example"
ACTION="${1:-}"

usage() {
  echo "Usage: ./scripts/deploy.sh <action>"
  echo
  echo "Actions: init | fmt | validate | plan | apply"
  echo
  echo "Configuration:"
  echo "  AWS_PROFILE         AWS CLI profile (default: example)"
  echo "  AWS_REGION          AWS region (default: eu-west-2)"
  echo "  EXPECTED_ACCOUNT_ID Optional 12-digit account safety check"
}

if [[ -z "$ACTION" ]]; then
  usage
  exit 1
fi

export AWS_PROFILE="${AWS_PROFILE:-example}"
export AWS_REGION="${AWS_REGION:-eu-west-2}"
export AWS_DEFAULT_REGION="$AWS_REGION"

BACKEND="backends/${ENVIRONMENT}.hcl"
VAR_FILE="environments/${ENVIRONMENT}.tfvars"
PLAN_FILE="${ENVIRONMENT}.tfplan"

case "$ACTION" in
  fmt)
    tofu fmt -recursive
    exit 0
    ;;
  init|validate|plan|apply) ;;
  *)
    echo "Error: invalid action '$ACTION'."
    usage
    exit 1
    ;;
esac

for file in "$BACKEND" "$VAR_FILE"; do
  if [[ ! -f "$file" ]]; then
    echo "Error: required file not found: $file"
    exit 1
  fi
done

if ! aws sts get-caller-identity --profile "$AWS_PROFILE" --region "$AWS_REGION" >/dev/null 2>&1; then
  echo "AWS session is missing or expired. Attempting AWS SSO login..."
  aws sso login --profile "$AWS_PROFILE"
fi

CURRENT_ACCOUNT_ID="$(aws sts get-caller-identity --profile "$AWS_PROFILE" --region "$AWS_REGION" --query Account --output text)"

if [[ -n "${EXPECTED_ACCOUNT_ID:-}" && "$CURRENT_ACCOUNT_ID" != "$EXPECTED_ACCOUNT_ID" ]]; then
  echo "Error: AWS account mismatch."
  echo "Expected: $EXPECTED_ACCOUNT_ID"
  echo "Current : $CURRENT_ACCOUNT_ID"
  exit 1
fi

printf 'Environment : %s\nAWS profile : %s\nAWS account : %s\nAWS region  : %s\nBackend     : %s\nVariables   : %s\n\n' \
  "$ENVIRONMENT" "$AWS_PROFILE" "$CURRENT_ACCOUNT_ID" "$AWS_REGION" "$BACKEND" "$VAR_FILE"

case "$ACTION" in
  init)
    tofu init -reconfigure -backend-config="$BACKEND"
    ;;
  validate)
    tofu init -reconfigure -backend-config="$BACKEND"
    tofu validate
    ;;
  plan)
    tofu init -reconfigure -backend-config="$BACKEND"
    tofu plan -var-file="$VAR_FILE" -out="$PLAN_FILE"
    echo "Plan saved to: $PLAN_FILE"
    ;;
  apply)
    if [[ ! -f "$PLAN_FILE" ]]; then
      echo "Error: saved plan not found: $PLAN_FILE"
      echo "Run ./scripts/deploy.sh plan first."
      exit 1
    fi
    tofu apply "$PLAN_FILE"
    ;;
esac
