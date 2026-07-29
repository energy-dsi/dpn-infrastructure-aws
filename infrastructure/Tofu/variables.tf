variable "project_name" {
  description = "Project short name used in resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS deployment region"
  type        = string
  default     = "eu-west-2"
}

variable "tags" {
  description = "Common tags applied to resources"
  type        = map(string)
  default     = {}
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
}

variable "azs" {
  description = "Availability zones used by the deployment"
  type        = list(string)

  validation {
    condition     = length(var.azs) == 2
    error_message = "Exactly two availability zones must be provided."
  }
}

variable "subnet_cidrs" {
  description = "CIDR blocks for each managed subnet tier"
  type = object({
    public = list(string)
    app    = list(string)
    data   = list(string)
    mgmt   = list(string)
  })

  validation {
    condition = (
      length(var.subnet_cidrs.public) == length(var.azs) &&
      length(var.subnet_cidrs.app) == length(var.azs) &&
      length(var.subnet_cidrs.data) == length(var.azs) &&
      length(var.subnet_cidrs.mgmt) == length(var.azs)
    )
    error_message = "Each subnet tier must contain one CIDR block per availability zone."
  }
}

variable "use_existing_vpc" {
  description = "Use an existing VPC instead of creating one"
  type        = bool
  default     = true
}

variable "existing_vpc_id" {
  description = "Existing VPC ID"
  type        = string
  default     = null

  validation {
    condition = (
      !var.use_existing_vpc ||
      (
        var.existing_vpc_id != null &&
        can(regex("^vpc-[0-9a-f]+$", var.existing_vpc_id))
      )
    )
    error_message = "existing_vpc_id must contain a valid VPC ID when use_existing_vpc is enabled."
  }
}

variable "create_igw" {
  description = "Create an Internet Gateway"
  type        = bool
  default     = false
}

variable "create_nat" {
  description = "Create NAT Gateways"
  type        = bool
  default     = false
}

variable "create_nlb_eips" {
  description = "Create static Elastic IP addresses for network load balancers"
  type        = bool
  default     = false
}

variable "transit_gateway_id" {
  description = "Existing Transit Gateway used for private subnet routing"
  type        = string
  default     = null

  validation {
    condition = (
      var.transit_gateway_id == null ||
      can(regex("^tgw-[0-9a-f]+$", var.transit_gateway_id))
    )
    error_message = "transit_gateway_id must contain a valid Transit Gateway ID."
  }
}

variable "allowed_egress_fqdns" {
  description = "Allowed FQDNs for controlled outbound connectivity"
  type        = list(string)
  default = [
    ".amazonaws.com",
    ".ecr.amazonaws.com",
    ".ecr.aws",
    ".eks.amazonaws.com",
    ".compute.amazonaws.com",
    "packages.us-east-1.amazonaws.com"
  ]
}

variable "enable_vpc_endpoints" {
  description = "Create VPC endpoints for private AWS service access"
  type        = bool
  default     = true
}

variable "enable_restrictive_endpoint_policies" {
  description = "Apply restrictive policies to supported VPC endpoints"
  type        = bool
  default     = false
}

variable "enable_vpc_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = false
}

variable "enable_network_firewall_logging" {
  description = "Enable Network Firewall logging"
  type        = bool
  default     = false
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version used by the EKS cluster"
  type        = string
  default     = "1.35"
}

variable "endpoint_private_access" {
  description = "Enable private access to the EKS API endpoint"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Enable public access to the EKS API endpoint"
  type        = bool
  default     = false
}

variable "endpoint_public_access_cidrs" {
  description = "CIDR blocks allowed to access the public EKS API endpoint"
  type        = list(string)
  default     = []
}

variable "cluster_log_types" {
  description = "Enabled EKS control-plane log types"
  type        = list(string)
  default = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]
}

variable "eks_authentication_mode" {
  description = "EKS cluster authentication mode"
  type        = string
  default     = "API_AND_CONFIG_MAP"

  validation {
    condition = contains(
      [
        "CONFIG_MAP",
        "API",
        "API_AND_CONFIG_MAP"
      ],
      var.eks_authentication_mode
    )
    error_message = "eks_authentication_mode must be CONFIG_MAP, API, or API_AND_CONFIG_MAP."
  }
}

variable "eks_bootstrap_cluster_creator_admin_permissions" {
  description = "Grant cluster administrator access to the cluster creator"
  type        = bool
  default     = true
}

variable "eks_access_entries" {
  description = "EKS access entries for IAM principals"
  type = map(object({
    principal_arn     = string
    policy_arn        = string
    access_scope_type = string
    namespaces        = optional(list(string))
  }))
  default = {}

  validation {
    condition = alltrue([
      for entry in values(var.eks_access_entries) :
      contains(["cluster", "namespace"], entry.access_scope_type)
    ])
    error_message = "Each EKS access scope must be cluster or namespace."
  }

  validation {
    condition = alltrue([
      for entry in values(var.eks_access_entries) :
      entry.access_scope_type != "namespace" ||
      try(length(entry.namespaces), 0) > 0
    ])
    error_message = "Namespace-scoped EKS access entries must define at least one namespace."
  }
}

variable "enable_cloudwatch_observability" {
  description = "Enable the Amazon CloudWatch Observability EKS add-on"
  type        = bool
  default     = true
}

variable "enable_efs_csi_driver" {
  description = "Enable the Amazon EFS CSI Driver EKS add-on"
  type        = bool
  default     = true
}

variable "system_node_group_name" {
  description = "System node group name"
  type        = string
  default     = "system"
}

variable "system_node_group_instance_types" {
  description = "Allowed instance types for the system node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "system_node_group_desired_size" {
  description = "Desired capacity of the system node group"
  type        = number
  default     = 1
}

variable "system_node_group_min_size" {
  description = "Minimum capacity of the system node group"
  type        = number
  default     = 1
}

variable "system_node_group_max_size" {
  description = "Maximum capacity of the system node group"
  type        = number
  default     = 2
}

variable "workload_node_group_name" {
  description = "Workload node group name"
  type        = string
  default     = "workload"
}

variable "workload_node_group_instance_types" {
  description = "Allowed instance types for the workload node group"
  type        = list(string)
  default     = ["m6id.2xlarge"]
}

variable "workload_node_group_desired_size" {
  description = "Desired capacity of the workload node group"
  type        = number
  default     = 3
}

variable "workload_node_group_min_size" {
  description = "Minimum capacity of the workload node group"
  type        = number
  default     = 3
}

variable "workload_node_group_max_size" {
  description = "Maximum capacity of the workload node group"
  type        = number
  default     = 3
}

variable "domain_name" {
  description = "Domain name used by the application ingress"
  type        = string
}

variable "ingress_hostname" {
  description = "DNS record name used by the application ingress"
  type        = string
}

variable "route53_zone_id" {
  description = "Route 53 hosted zone ID"
  type        = string
}

variable "application_namespace" {
  description = "Default Kubernetes namespace for application workloads"
  type        = string
  default     = "applications"
}

variable "alb_controller_chart_version" {
  description = "AWS Load Balancer Controller Helm chart version"
  type        = string
  default     = "1.14.0"
}

variable "alb_controller_image_tag" {
  description = "AWS Load Balancer Controller container image tag"
  type        = string
  default     = "v2.14.0"
}

variable "enable_kubernetes_platform" {
  description = "Deploy Kubernetes platform resources through the Kubernetes and Helm providers"
  type        = bool
  default     = false
}

variable "enable_waf" {
  description = "Enable AWS WAF"
  type        = bool
  default     = false
}

variable "waf_rate_limit" {
  description = "Maximum number of requests allowed during the WAF evaluation period"
  type        = number
  default     = 2000
}

variable "blocked_country_codes" {
  description = "ISO country codes blocked by AWS WAF"
  type        = list(string)
  default     = []
}

variable "waf_allowed_http_methods" {
  description = "HTTP methods allowed by AWS WAF"
  type        = list(string)
  default = [
    "GET",
    "POST",
    "PUT",
    "PATCH",
    "DELETE",
    "HEAD",
    "OPTIONS"
  ]
}

variable "waf_blocked_user_agent_regexes" {
  description = "User-agent patterns blocked by AWS WAF"
  type        = list(string)
  default = [
    "(?i).*sqlmap.*",
    "(?i).*nikto.*",
    "(?i).*nmap.*",
    "(?i).*masscan.*",
    "(?i).*acunetix.*",
    "(?i).*dirbuster.*",
    "(?i).*zaproxy.*"
  ]
}

variable "enable_waf_logging" {
  description = "Enable AWS WAF logging"
  type        = bool
  default     = false
}

variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "platform"
}

variable "db_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "16.3"
}

variable "db_instance_class" {
  description = "RDS database instance class"
  type        = string
  default     = "db.t4g.medium"
}

variable "db_allocated_storage" {
  description = "Initial RDS storage capacity in GiB"
  type        = number
  default     = 30
}

variable "db_max_allocated_storage" {
  description = "Maximum RDS autoscaling storage capacity in GiB"
  type        = number
  default     = 100
}

variable "db_admin_username" {
  description = "RDS administrator username"
  type        = string
  default     = "platformadmin"
}

variable "db_admin_secret_name" {
  description = "Secrets Manager secret name for RDS administrator credentials"
  type        = string
  default     = ""
}

variable "backup_retention_days" {
  description = "RDS backup retention period in days"
  type        = number
  default     = 7
}

variable "data_bucket_name" {
  description = "Private S3 bucket used for application data"
  type        = string
}

variable "application_bucket_name" {
  description = "Private S3 bucket used by application workloads"
  type        = string
}

variable "data_bucket_force_destroy" {
  description = "Allow deletion of the data bucket when it contains objects"
  type        = bool
  default     = false
}

variable "data_bucket_noncurrent_version_expiration_days" {
  description = "Retention period for noncurrent S3 object versions"
  type        = number
  default     = 90
}

variable "application_secret_arns" {
  description = "Secrets Manager ARNs accessible to the application service account"
  type        = list(string)
  default     = []
}

variable "ecr_image_tag_mutability" {
  description = "ECR image tag mutability setting"
  type        = string
  default     = "IMMUTABLE"

  validation {
    condition = contains(
      [
        "MUTABLE",
        "IMMUTABLE"
      ],
      var.ecr_image_tag_mutability
    )
    error_message = "ecr_image_tag_mutability must be MUTABLE or IMMUTABLE."
  }
}

variable "ecr_scan_on_push" {
  description = "Enable ECR image scanning when an image is pushed"
  type        = bool
  default     = true
}

variable "log_retention_in_days" {
  description = "CloudWatch Logs retention period in days"
  type        = number
  default     = 90
}

variable "create_log_s3_buckets" {
  description = "Create S3 buckets for service log delivery"
  type        = bool
  default     = false
}

variable "enable_guardduty" {
  description = "Enable Amazon GuardDuty"
  type        = bool
  default     = false
}

variable "enable_security_hub" {
  description = "Enable AWS Security Hub"
  type        = bool
  default     = false
}

variable "enable_cloudtrail" {
  description = "Enable AWS CloudTrail"
  type        = bool
  default     = false
}

variable "enable_aws_config" {
  description = "Enable AWS Config"
  type        = bool
  default     = false
}

variable "enable_session_manager_preferences" {
  description = "Create Session Manager preferences"
  type        = bool
  default     = false
}

variable "ssm_idle_session_timeout_minutes" {
  description = "Session Manager idle timeout in minutes"
  type        = number
  default     = 20
}

variable "ssm_max_session_duration_minutes" {
  description = "Session Manager maximum session duration in minutes"
  type        = number
  default     = 60
}

variable "ssm_run_as_default_user" {
  description = "Default operating-system user for Session Manager sessions"
  type        = string
  default     = "ssm-user"
}

variable "irsa_service_accounts" {
  description = "IRSA service accounts and their IAM policies"
  type = map(object({
    namespace       = string
    service_account = string
    policy_json     = string
  }))
  default = {}
}
variable "enable_s3_malware_protection" {
  description = "Enable GuardDuty Malware Protection for the application S3 bucket"
  type        = bool
  default     = false
}
variable "enable_management_host_backend_access" {
  description = "Allow the management host to access the OpenTofu remote-state backend"
  type        = bool
  default     = false
}

variable "terraform_state_bucket_name" {
  description = "S3 bucket containing the OpenTofu remote state"
  type        = string
  default     = null
}

variable "terraform_lock_table_name" {
  description = "DynamoDB table used for OpenTofu state locking"
  type        = string
  default     = null
}