# Accessing the platform

The platform uses a private EKS control plane.Infrastructure is administered through a dedicated management host. The EKS control plane is private and is not intended to be accessed directly from developer workstations.

Administrative access is provided through:

- AWS IAM Identity Center (AWS SSO)
- AWS Systems Manager Session Manager
- a dedicated management host deployed as part of the infrastructure

The management host is the primary administration point for the Kubernetes cluster.

No inbound SSH access is required.

---

# Management host

Each environment deploys a dedicated EC2 management host inside the VPC.

The host is intended for:

- Kubernetes administration
- OpenTofu operations
- AWS CLI access
- kubectl
- Helm
- troubleshooting and diagnostics

Access is performed through AWS Systems Manager Session Manager.

Example:

```bash
aws ssm start-session \
    --target <instance-id> \
    --profile dpn-dev
```

The current instance ID can be obtained from the OpenTofu outputs:

```bash
tofu output management_host_instance_id
```

or from the AWS Console.

---

# Kubernetes access

The EKS API endpoint is private and is intended to be accessed from the management host.

After connecting to the management host, configure kubectl:

DEV

```bash
aws eks update-kubeconfig \
    --name <cluster-name> \
    --region eu-west-2
```

TEST

```bash
aws eks update-kubeconfig \
    --name <cluster-name> \
    --region eu-west-2
```

Verify connectivity:

```bash
kubectl get nodes
kubectl get pods -A
```

Authentication is handled through AWS IAM Identity Center and EKS Access Entries. No static Kubernetes credentials are stored on the host.