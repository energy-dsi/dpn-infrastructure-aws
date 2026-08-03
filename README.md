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
.
├── docs/                       # Prerequisites, deployment, and access guides
│   ├── prerequisites.md
│   ├── deployment.md
│   └── access.md
├── infrastructure/Tofu/
│   ├── bootstrap/                 # Remote-state resources
│   │   ├── environments/example.tfvars
│   │   └── backends/example.hcl
│   ├── backends/example.hcl       # Main stack backend configuration
│   ├── environments/example.tfvars
│   ├── modules/                   # Reusable infrastructure modules
│   ├── scripts/deploy.sh          # Single-environment deployment helper
│   ├── main.tf
│   ├── providers.tf
│   ├── variables.tf
│   └── outputs.tf
├── CONTRIBUTING.md
├── ACKNOWLEDGEMENTS.md
├── CODE_OF_CONDUCT.md
├── CHANGELOG.md
├── MAINTAINERS.md
├── SECURITY.md
├── LICENSE.md
├── OGL_LICENSE.md
├── NOTICE.md
└── README.md
```

## Version requirements

Tested with:

- OpenTofu CLI `>= 1.8.0` (see `infrastructure/Tofu/providers.tf`)
- AWS provider `~> 5.53`
- Kubernetes provider `~> 2.33`
- Helm provider `~> 2.15`
- Amazon EKS Kubernetes version `1.35` in the example configuration (`kubernetes_version` in `environments/example.tfvars`)

Confirm current Amazon EKS version support and add-on compatibility before changing `kubernetes_version`.

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

### 4. Verify the deployment

```bash
aws eks update-kubeconfig \
  --name "$(tofu output -raw eks_cluster_name)" \
  --region "$AWS_REGION" \
  --profile "$AWS_PROFILE"

kubectl get nodes
kubectl get pods -n kube-system
kubectl get deployment -n platform aws-load-balancer-controller
```

If `enable_kubernetes_platform = false` (the example default), the last command will not return results yet — see [Enabling Kubernetes platform resources](docs/deployment.md#enabling-kubernetes-platform-resources). For private-endpoint access via the management host, see [Platform access](docs/access.md).

## Important design decisions to review

- **VPC ownership:** the example creates a new VPC. Set `use_existing_vpc = true` only with a valid existing VPC ID.
- **Egress:** `create_nat = false` by default. **EKS managed node groups require outbound reachability to the EKS API, Amazon ECR, and AWS STS during node bootstrap.** Configure Transit Gateway routing, VPC endpoints, or another approved outbound path *before* running `tofu apply`, or node groups will fail to join the cluster.
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
rg -n '(AKIA|ASIA)[A-Z0-9]{16}|-----BEGIN .*PRIVATE KEY-----|arn:(aws|aws-cn|aws-us-gov):[a-zA-Z0-9-]+:[a-zA-Z0-9-]*:[0-9]{12}:' .
```

Expected documentation-only account IDs and example ARNs should be reviewed manually.

## Public Funding Acknowledgment

This repository has been developed with public funding as part of the Data Sharing Infrastructure (DSI), a UK Government initiative. DSI, alongside its partners, has invested in this work to advance open, secure, and reusable digital twin technologies for any organisation, whether from the public or private sector, irrespective of size.

## License

This repository contains both source code and documentation, which are covered by different licenses:

- **Code:** Licensed under the [Apache License 2.0](./LICENSE.md).
- **Documentation:** Licensed under the [Open Government Licence v3.0 (OGL-UK-3.0)](./OGL_LICENSE.md).

By contributing to this repository, you agree that your contributions will be licenced under these terms.

## Security and Responsible Disclosure

We take security seriously. If you believe you have found a security vulnerability in this repository, please follow our responsible disclosure process outlined in [SECURITY.md](./SECURITY.md).

## Contributing

We welcome contributions that align with the Programme's objectives. See [CONTRIBUTING.md](./CONTRIBUTING.md) for the contribution model and [CODE_OF_CONDUCT.md](./CODE_OF_CONDUCT.md) for expected behaviour.

## Acknowledgements

This repository has benefited from collaboration with various organisations. See [ACKNOWLEDGEMENTS.md](./ACKNOWLEDGEMENTS.md) for details.

## Maintainers and Release History

See [MAINTAINERS.md](./MAINTAINERS.md) for current repository maintainers and [CHANGELOG.md](./CHANGELOG.md) for release history.

## Support and Contact

For questions or support, check the repository [Issues](https://github.com/energy-dsi/dpn-infrastructure-aws/issues) or contact the DSI team at [dsi@neso.energy](mailto:dsi@neso.energy).

## Maintained by the National Energy System Operator (NESO)

Copyright 2026 NESO and the Crown. This work has been developed by NESO using content licensed by the Department for Business and Trade (UK) under the Open Government Licence v3.0 (OGL-UK-3.0). See [OGL_LICENSE.md](./OGL_LICENSE.md) for full terms.
