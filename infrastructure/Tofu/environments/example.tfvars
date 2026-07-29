# Replace every EXAMPLE or placeholder value before deployment.
# This sample uses documentation-only AWS account ID 111122223333.

project_name = "example-platform"
environment  = "example"
aws_region   = "eu-west-2"

cluster_name       = "eks-example-platform-example-eu-west-2"
kubernetes_version = "1.35"

# Example RFC1918 address space. Confirm that it does not overlap with your
# existing networks, VPNs, Transit Gateway attachments, or peered VPCs.
vpc_cidr = "10.42.0.0/20"

azs = [
  "eu-west-2a",
  "eu-west-2b"
]

subnet_cidrs = {
  public = [
    "10.42.0.0/24",
    "10.42.1.0/24"
  ]

  mgmt = [
    "10.42.2.0/24",
    "10.42.3.0/24"
  ]

  app = [
    "10.42.4.0/22",
    "10.42.8.0/22"
  ]

  data = [
    "10.42.12.0/23",
    "10.42.14.0/23"
  ]
}

# Set true and supply an existing VPC ID when integrating with an established
# landing zone. The example creates a new VPC.
use_existing_vpc = false
existing_vpc_id  = null

# Set according to your ingress and egress architecture.
create_igw      = true
create_nat      = false
create_nlb_eips = false

# Optional. Set to a valid tgw-* ID for centralized enterprise routing.
transit_gateway_id = null

enable_s3_malware_protection = false
enable_management_host_backend_access = false

# S3 bucket names are globally unique. Replace these values.
application_bucket_name = "example-platform-example-111122223333-eu-west-2-application"
data_bucket_name        = "example-platform-example-111122223333-eu-west-2-data"

# Replace with your DNS values before enabling Kubernetes platform resources.
domain_name      = "platform.example.org"
ingress_hostname = "example"
route53_zone_id  = "Z000000000000EXAMPLE"

endpoint_private_access = true
endpoint_public_access  = false

# Keep bootstrap permissions enabled for the first deployment only if your
# operating model requires it. Review after access entries are verified.
eks_authentication_mode                         = "API_AND_CONFIG_MAP"
eks_bootstrap_cluster_creator_admin_permissions = true

enable_cloudwatch_observability = true
enable_efs_csi_driver           = true

# Replace these example ARNs with roles from your AWS account. Standard IAM
# roles or IAM Identity Center reserved roles may be used.
eks_access_entries = {
  platform_admin = {
    principal_arn     = "arn:aws:iam::111122223333:role/ExampleEKSPlatformAdmin"
    policy_arn        = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
    access_scope_type = "cluster"
  }

  application_team = {
    principal_arn     = "arn:aws:iam::111122223333:role/ExampleEKSApplicationTeam"
    policy_arn        = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"
    access_scope_type = "namespace"
    namespaces        = ["applications"]
  }
}

system_node_group_instance_types = ["t3.medium"]
system_node_group_desired_size   = 1
system_node_group_min_size       = 1
system_node_group_max_size       = 2

workload_node_group_instance_types = ["m6i.large"]
workload_node_group_desired_size   = 2
workload_node_group_min_size       = 2
workload_node_group_max_size       = 4

db_name                  = "platform"
db_engine_version        = "16.3"
db_instance_class        = "db.t4g.medium"
db_allocated_storage     = 30
db_max_allocated_storage = 100
db_admin_username        = "platformadmin"
backup_retention_days    = 7

db_admin_secret_name = "example-platform/example/postgres/admin"

data_bucket_force_destroy                      = false
data_bucket_noncurrent_version_expiration_days = 90

application_namespace        = "applications"
alb_controller_chart_version = "1.14.0"
alb_controller_image_tag     = "v2.14.0"

# Disabled by default so infrastructure can be created before kubectl/Helm
# providers need connectivity to the private EKS endpoint.
enable_kubernetes_platform = false

enable_waf     = false
waf_rate_limit = 2000

blocked_country_codes = []

waf_allowed_http_methods = [
  "GET",
  "POST",
  "PUT",
  "PATCH",
  "DELETE",
  "HEAD",
  "OPTIONS"
]

waf_blocked_user_agent_regexes = [
  "(?i).*sqlmap.*",
  "(?i).*nikto.*",
  "(?i).*nmap.*",
  "(?i).*masscan.*"
]

# Security services may already be managed centrally by AWS Organizations.
# Confirm ownership before enabling them in this account.
enable_guardduty                   = false
enable_security_hub                = false
enable_cloudtrail                  = false
enable_aws_config                  = false
enable_session_manager_preferences = false

enable_vpc_endpoints                 = true
enable_restrictive_endpoint_policies = false

enable_vpc_flow_logs            = false
enable_network_firewall_logging = false
enable_waf_logging              = false

create_log_s3_buckets = false

allowed_egress_fqdns = [
  ".amazonaws.com",
  ".ecr.amazonaws.com",
  ".ecr.aws",
  ".eks.amazonaws.com",
  ".compute.amazonaws.com",
  "packages.us-east-1.amazonaws.com"
]

irsa_service_accounts = {
  external-secrets = {
    namespace       = "external-secrets"
    service_account = "external-secrets-sa"

    policy_json = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": "arn:aws:secretsmanager:*:111122223333:secret:example-platform/example/*"
    }
  ]
}
POLICY
  }
}

tags = {
  project      = "example-platform"
  environment  = "example"
  managed_by   = "opentofu"
  data_class   = "internal"
  architecture = "aws-eks-platform"
}
