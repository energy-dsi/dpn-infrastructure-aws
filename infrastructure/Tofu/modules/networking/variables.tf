variable "project_name" {
  description = "Project short name"
  type        = string
}

variable "environment" {
  description = "Environment name, for example dev-01"
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
  description = "Availability Zones used by this deployment"
  type        = list(string)

  validation {
    condition     = length(var.azs) == 2
    error_message = "This deployment currently requires exactly two Availability Zones."
  }
}

variable "subnet_cidrs" {
  description = "CIDR ranges for platform-managed subnet tiers, with one CIDR per Availability Zone"

  type = object({
    public = list(string)
    app    = list(string)
    data   = list(string)
    mgmt   = list(string)
  })

  validation {
    condition = alltrue([
      length(var.subnet_cidrs.public) == length(var.azs),
      length(var.subnet_cidrs.app) == length(var.azs),
      length(var.subnet_cidrs.data) == length(var.azs),
      length(var.subnet_cidrs.mgmt) == length(var.azs)
    ])

    error_message = "Each subnet tier must contain exactly one CIDR per configured Availability Zone."
  }
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
  description = "Enable VPC flow logging resources"
  type        = bool
  default     = true
}

variable "enable_network_firewall_logging" {
  description = "Enable AWS Network Firewall logging configuration"
  type        = bool
  default     = true
}

variable "use_existing_vpc" {
  description = "Use an existing VPC instead of creating a new one"
  type        = bool
  default     = false
}

variable "existing_vpc_id" {
  description = "Existing VPC ID to use when use_existing_vpc is true"
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

    error_message = "existing_vpc_id must contain a valid VPC ID when use_existing_vpc is true."
  }
}

variable "create_igw" {
  description = "Create and attach an Internet Gateway to the selected VPC"
  type        = bool
  default     = true
}

variable "existing_internet_gateway_id" {
  description = "Existing Internet Gateway ID to use when create_igw is false"
  type        = string
  default     = null
}

variable "create_nat" {
  description = "Create NAT Gateways for application subnet egress"
  type        = bool
  default     = true
}

variable "transit_gateway_id" {
  description = "Transit Gateway ID used for subnet egress when NAT and direct IGW routing are not used"
  type        = string
  default     = null

  validation {
    condition = (
      var.create_nat ||
      (
        var.transit_gateway_id != null &&
        can(regex("^tgw-[0-9a-f]+$", var.transit_gateway_id))
      )
    )

    error_message = "transit_gateway_id must contain a valid TGW ID when create_nat is false."
  }
}

variable "create_nlb_eips" {
  description = "Create static Elastic IPs for internet-facing NLBs"
  type        = bool
  default     = false
}