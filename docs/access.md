# Platform access

The reference configuration uses a private Amazon EKS API endpoint.

## AWS authentication

Authenticate with your approved AWS CLI profile:

```bash
aws sso login --profile example
aws sts get-caller-identity --profile example
```

## Management host

The code includes a single management host intended to be reached using AWS Systems Manager Session Manager. It is not an Auto Scaling Group and should not be treated as a highly available service.

Start a session using the instance ID from the OpenTofu outputs or AWS console:

```bash
aws ssm start-session --target i-EXAMPLE --profile example --region eu-west-2
```

## EKS kubeconfig

From a network location that can reach the private EKS endpoint:

```bash
aws eks update-kubeconfig \
  --name eks-example-platform-example-eu-west-2 \
  --region eu-west-2 \
  --profile example

kubectl get nodes
```

Access is granted through EKS Access Entries. Replace the example IAM principal ARNs with your own roles and review the assigned cluster-access policies.
