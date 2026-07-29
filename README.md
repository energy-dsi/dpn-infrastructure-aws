# AWS EKS Platform Reference

An anonymized, single-environment OpenTofu reference implementation for deploying an enterprise-oriented Amazon EKS platform on AWS.

This repository is intended as a **starting point**, not a turnkey production deployment. Replace the example values, review the architecture against your AWS landing zone, and complete your own security, networking, cost, and operational assessments before applying it.

## What it deploys

The codebase includes reusable modules for:

- VPC networking across two Availability Zones
- public, application, data, and management subnet tiers
- optional integration with an existing VPC and Transit Gateway
- Amazon EKS with private worker nodes and managed node groups
- EKS Access Entries and IAM Roles for Service Accounts (IRSA)
- a Systems Manager-accessed management host
- AWS Load Balancer Controller and ingress resources
- Amazon ECR, S3, EFS, RDS PostgreSQL, and Secrets Manager
- CloudWatch, CloudTrail, VPC Flow Logs, AWS Config, GuardDuty, and Security Hub
- optional WAF and security-event notifications
- encrypted remote OpenTofu state in S3 with DynamoDB locking

Most optional security and platform integrations are disabled in the example configuration. Enable them only after confirming that they are not already managed centrally by AWS Organizations or your landing-zone tooling.

## Repository layout

```text
infrastructure/Tofu/
├── bootstrap/                 # Remote-state resources
│   ├── environments/example.tfvars
│   └── backends/example.hcl
├── backends/example.hcl       # Main stack backend configuration
├── environments/example.tfvars
├── modules/                   # Reusable infrastructure modules
├── scripts/deploy.sh          # Single-environment deployment helper
├── main.tf
├── providers.tf
├── variables.tf
└── outputs.tf
```

## Before you deploy

Read [Prerequisites](docs/prerequisites.md) and replace all placeholders in:

- `infrastructure/Tofu/environments/example.tfvars`
- `infrastructure/Tofu/bootstrap/environments/example.tfvars`
- `infrastructure/Tofu/backends/example.hcl`
- `infrastructure/Tofu/bootstrap/backends/example.hcl`

Find placeholders with:

```bash
rg -n 'EXAMPLE|111122223333|00000000-0000-4000-8000-000000000000|Z000000000000EXAMPLE|example\.org' .
```

## Deployment sequence

### 1. Bootstrap remote state

The first bootstrap apply normally uses local state:

```bash
cd infrastructure/Tofu/bootstrap
cp environments/example.tfvars environments/local.auto.tfvars
# Edit local.auto.tfvars with your values.
tofu init
tofu plan
tofu apply
```

Record the generated bucket, DynamoDB table, and KMS key outputs. Update both `backends/example.hcl` files with those values. Remove `local.auto.tfvars` after use; it is ignored by Git.

### 2. Configure AWS authentication

The helper script defaults to an AWS CLI profile named `example`:

```bash
aws configure sso --profile example
aws sso login --profile example
```

You can use another profile:

```bash
export AWS_PROFILE=my-platform-profile
export AWS_REGION=eu-west-2
export EXPECTED_ACCOUNT_ID=111122223333
```

### 3. Deploy the platform

```bash
cd infrastructure/Tofu
./scripts/deploy.sh fmt
./scripts/deploy.sh init
./scripts/deploy.sh validate
./scripts/deploy.sh plan
./scripts/deploy.sh apply
```

Review the generated plan carefully before applying it.

## Important design decisions to review

- **VPC ownership:** the example creates a new VPC. Set `use_existing_vpc = true` only with a valid existing VPC ID.
- **Egress:** `create_nat = false`. Provide Transit Gateway routing, VPC endpoints, or another approved outbound path before expecting private workloads to reach external services.
- **Ingress:** the example enables an Internet Gateway but does not enable static NLB EIPs. Adapt this to your ingress model.
- **Private EKS API:** administration requires network reachability to the private endpoint, commonly through the management host or a connected enterprise network.
- **DNS:** replace the example Route 53 values and confirm hosted-zone ownership.
- **IAM:** replace all example principal ARNs and apply least privilege.
- **Kubernetes versions:** verify current Amazon EKS and add-on compatibility before deployment.
- **Costs:** EKS, EC2, RDS, EFS, NAT Gateway, Transit Gateway, logging, and security services can incur material charges.

## Validation

Run these checks before publishing or deploying a modified copy:

```bash
tofu fmt -check -recursive
shellcheck infrastructure/Tofu/scripts/deploy.sh
rg -n '(AKIA|ASIA)[A-Z0-9]{16}|-----BEGIN .*PRIVATE KEY-----|[0-9]{12}|arn:aws:iam::' .
```

Expected documentation-only account IDs and example ARNs should be reviewed manually.

## Security

Do not commit credentials, state files, plans, kubeconfig files, private keys, or production identifiers. See [SECURITY.md](SECURITY.md).

## License

Licensed under the Apache License 2.0. See [LICENSE](LICENSE).
