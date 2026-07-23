# Deployment Guide

This document describes the current deployment process for the DPN AWS infrastructure.

The infrastructure is managed with OpenTofu and currently supports two environments:

| Environment | AWS Account | Region |
|------------|-------------|--------|
| DEV | Account-Dev | eu-west-2 |
| TEST | Account-Test | eu-west-2 |

Both environments follow the same deployment process and use the same codebase. Environment-specific values are stored in dedicated backend and tfvars files.

---

# Authentication

Infrastructure deployments use AWS IAM Identity Center (AWS SSO).

No long-lived IAM users or access keys are required.

Expected AWS CLI profiles:

```text
dpn-dev
dpn-test
```

Verify the active identity:

```bash
aws sts get-caller-identity --profile dpn-dev
aws sts get-caller-identity --profile dpn-test
```

---

# Bootstrap

Bootstrap is only required once per AWS account.

It creates the remote OpenTofu backend resources:

- S3 state bucket
- DynamoDB state lock table

Example:

```bash
cd infrastructure/Tofu/bootstrap

tofu init
tofu plan -var-file=environments/dev.tfvars
tofu apply -var-file=environments/dev.tfvars
```

The same process applies to TEST using `test.tfvars`.

---

# Infrastructure deployment

Move to the main infrastructure directory:

```bash
cd infrastructure/Tofu
```

Initialize the correct backend:

DEV

```bash
tofu init -backend-config=backends/dev.hcl
```

TEST

```bash
tofu init -backend-config=backends/test.hcl
```

Generate a deployment plan:

DEV

```bash
tofu plan \
    -var-file=environments/dev.tfvars \
    -out=dev.plan
```

TEST

```bash
tofu plan \
    -var-file=environments/test.tfvars \
    -out=test.plan
```

Review the plan before applying.

Apply:

```bash
tofu apply dev.plan
```

or

```bash
tofu apply test.plan
```

---

# Secrets

Sensitive values are never stored in the repository.

Passwords and generated credentials are stored in AWS Secrets Manager.

Infrastructure state is stored remotely in the environment-specific S3 backend.

---

# Deployment principles

Some general rules that should be followed when extending the platform:

- keep DEV and TEST functionally aligned
- deploy changes to DEV before TEST
- always review the execution plan before applying
- avoid manual changes in AWS whenever possible
- manage infrastructure only through OpenTofu
- use AWS SSO identities instead of static IAM credentials

---

# Current platform

The repository currently manages:

- Networking
- EKS
- IAM roles
- IRSA
- ECR
- S3
- CloudWatch
- GuardDuty
- VPC Flow Logs
- Management Host
- AWS Load Balancer Controller
- Kubernetes access configuration

Additional services will be added as the platform evolves.