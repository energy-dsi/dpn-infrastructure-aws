# Security policy

## Reporting a vulnerability

Do not open a public issue containing sensitive security details. Contact the repository maintainers privately using the security-reporting channel defined by the organization hosting the fork.

## Sensitive data

Never commit:

- AWS access keys, session tokens, passwords, or private keys
- OpenTofu state or plan files
- production account IDs, VPC IDs, Transit Gateway IDs, KMS key IDs, or private DNS names
- kubeconfig files or Kubernetes service-account tokens
- proprietary diagrams, customer names, internal IP plans, or private operational documentation

Run secret scanning before every public release.
