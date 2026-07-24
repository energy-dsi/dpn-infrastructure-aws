# DPN AWS Infrastructure

This repo contains the AWS infrastructure code for the DPN platform.

At the moment it is used for the DEV and TEST environments. The goal is to keep both environments aligned and to make the deployment process simple, repeatable and based on AWS SSO instead of long-lived access keys.

## What is included

The current platform includes:

- VPC and subnet layout
- EKS clusters
- private worker nodes
- management host access
- AWS Load Balancer Controller
- NLB support with static public IPs
- ECR repositories
- S3 buckets for application and data use
- IAM roles and IRSA for Kubernetes workloads
- Secrets Manager access pattern
- GuardDuty findings integration
- GuardDuty Malware Protection for S3
- EventBridge and SNS notifications
- VPC Flow Logs
- CloudWatch log groups
- DEV and TEST backend state configuration

## Environments

| DEV | <YOUR-AWS-DEV-ACCOUNT> | `eu-west-2` |
| TEST | <YOUR-AWS-DEV-ACCOUNT> | `eu-west-2` |

## Repository layout


├── docs/
├── infrastructure/
│   └── Tofu/
│       ├── backends/
│       ├── bootstrap/
│       ├── environments/
│       ├── modules/
│       ├── scripts/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── providers.tf
├── .github/
├── .gitignore
├── PIPELINES.md
└── README.md