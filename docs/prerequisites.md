# Prerequisites

## Workstation tools

Install:

- OpenTofu
- AWS CLI v2
- `kubectl`
- Helm
- Git
- `jq`
- `shellcheck` and `ripgrep` for local quality checks

## AWS account prerequisites

Before deployment, confirm:

1. An AWS account with sufficient service quotas and permissions.
2. AWS IAM Identity Center or another approved authentication method.
3. IAM principals for platform administrators and application teams.
4. Two Availability Zones in the target region.
5. A non-overlapping VPC CIDR and subnet plan.
6. A decision on new versus existing VPC ownership.
7. A defined outbound-egress path: NAT Gateway, Transit Gateway/shared egress, proxy, or VPC endpoints.
8. Route 53 hosted-zone ownership and DNS delegation when ingress resources are enabled.
9. Whether GuardDuty, Security Hub, AWS Config, CloudTrail, and logging are already organization-managed.
10. Service quotas for EKS, EC2, EIPs, VPC endpoints, RDS, EFS, and related resources.

## Required parameter replacements

The public example uses AWS documentation account ID `111122223333` and synthetic resource identifiers. Replace:

- AWS account ID
- region and Availability Zones
- VPC and subnet CIDRs
- existing VPC and Transit Gateway IDs, when used
- S3 bucket names
- Route 53 zone ID and domain name
- IAM/EKS access-entry principal ARNs
- Secrets Manager ARNs and secret names
- backend bucket, DynamoDB table, and KMS key ARN
- instance types and scaling values
- security-service enablement flags
- tags and data-classification values

## Network reachability

With `endpoint_public_access = false`, the EKS API is private. Ensure that the machine running Kubernetes and Helm operations can resolve and reach the endpoint. Common patterns include:

- AWS Systems Manager Session Manager to the management host
- a VPN or Direct Connect connection
- a connected shared-services VPC
- a CI/CD runner hosted inside the network

## Deployment ownership

Clarify who owns:

- the VPC and route tables
- Transit Gateway attachments and routes
- centralized egress/firewall policy
- DNS and certificates
- organization-wide security services
- encryption keys
- backup and retention policies
- Kubernetes add-ons and application namespaces
