variable "project_name" {
  description = "Project short name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "azs" {
  description = "AZs used by this deployment"
  type        = list(string)
}

variable "subnet_cidrs" {
  description = "Per-tier subnet CIDRs, one per AZ"
  type = object({
    public = list(string)
    app    = list(string)
    data   = list(string)
    fw     = list(string)
    tgw    = list(string)
    mgmt   = list(string)
  })
}

variable "allowed_egress_fqdns" {
  description = "Allowed domains for stateful firewall rules"
  type        = list(string)
  default     = []
}

variable "firewall_flow_log_group_arn" {
  description = "CloudWatch log group ARN for firewall flow logs"
  type        = string
  default     = null
}

variable "vpc_flow_log_group_arn" {
  description = "CloudWatch log group ARN for VPC flow logs"
  type        = string
  default     = null
}

variable "firewall_alert_log_group_arn" {
  description = "CloudWatch log group ARN for firewall alert logs"
  type        = string
  default     = null
}

variable "enable_vpc_endpoints" {
  description = "Enable interface and gateway VPC endpoints for private AWS API access"
  type        = bool
  default     = true
}

variable "enable_restrictive_endpoint_policies" {
  description = "Apply restrictive endpoint policies to gateway and interface endpoints"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}


variable "enable_vpc_flow_logs" {
  description = "Enable VPC flow logging resources. Uses explicit boolean to avoid unknown count during planning."
  type        = bool
  default     = true
}

variable "enable_network_firewall_logging" {
  description = "Enable AWS Network Firewall logging configuration. Uses explicit boolean to avoid unknown count during planning."
  type        = bool
  default     = true
}
variable "use_existing_vpc" {
  description = "Use an existing VPC instead of creating a new one."
  type        = bool
  default     = false
}

variable "existing_vpc_id" {
  description = "Existing VPC ID to use when use_existing_vpc is true."
  type        = string
  default     = null
}

variable "create_igw" {
  description = "Create and attach an Internet Gateway to the selected VPC."
  type        = bool
  default     = true
}

variable "existing_internet_gateway_id" {
  description = "Existing Internet Gateway ID to use when create_igw is false."
  type        = string
  default     = null
}

variable "create_nat" {
  description = "Create NAT Gateways for private/application subnet egress."
  type        = bool
  default     = true
}

variable "transit_gateway_id" {
  description = "Transit Gateway ID used for private/application subnet egress when create_nat is false."
  type        = string
  default     = null
}
variable "create_nlb_eips" {
  description = "Create static Elastic IPs for internet-facing NLBs."
  type        = bool
  default     = false
}