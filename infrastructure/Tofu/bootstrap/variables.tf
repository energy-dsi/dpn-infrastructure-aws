

variable "aws_region" {
  description = "AWS region for bootstrap resources"
  type        = string
  default     = "eu-west-2"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "AWS region must be a valid region identifier, for example eu-west-2."
  }
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "platform"

  validation {
    condition     = can(regex("^[a-z0-9]{1,8}$", var.project_name))
    error_message = "Project name must contain 1-8 lowercase alphanumeric characters."
  }
}

variable "environment" {
  description = "Environment name, for example dev-01, test-01, or prod"

  type = string

  validation {
    condition = can(
      regex(
        "^([a-z0-9]|[a-z0-9][a-z0-9-]{0,13}[a-z0-9])$",
        var.environment
      )
    )

    error_message = "Environment must contain 1-15 lowercase alphanumeric or hyphen characters and cannot start or end with a hyphen."
  }
}

variable "tfstate_bucket_name" {
  description = "Globally unique S3 bucket name used to store OpenTofu state files"

  type = string

  validation {
    condition = can(
      regex(
        "^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$",
        var.tfstate_bucket_name
      )
    )

    error_message = "S3 bucket name must contain 3-63 lowercase alphanumeric or hyphen characters and cannot start or end with a hyphen."
  }
}

variable "tfstate_dynamodb_table" {
  description = "DynamoDB table name used for OpenTofu state locking"

  type = string

  validation {
    condition = can(
      regex(
        "^[a-zA-Z0-9_.-]{3,255}$",
        var.tfstate_dynamodb_table
      )
    )

    error_message = "DynamoDB table name must contain 3-255 alphanumeric, underscore, period, or hyphen characters."
  }
}

variable "enable_cloudtrail_audit" {
  description = "Enable CloudTrail audit logging for state-backend access"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention period in days"
  type        = number
  default     = 30

  validation {
    condition = contains(
      [
        1,
        3,
        5,
        7,
        14,
        30,
        60,
        90,
        120,
        150,
        180,
        365,
        400,
        545,
        731,
        1827,
        3653
      ],
      var.log_retention_days
    )

    error_message = "Log retention must be a valid CloudWatch Logs retention period."
  }
}

variable "enable_mfa_delete" {
  description = "Enable MFA Delete on the S3 state bucket"
  type        = bool
  default     = false
}

variable "kms_key_deletion_window_days" {
  description = "KMS key deletion waiting period in days"
  type        = number
  default     = 7

  validation {
    condition = (
      var.kms_key_deletion_window_days >= 7 &&
      var.kms_key_deletion_window_days <= 30
    )

    error_message = "KMS key deletion window must be between 7 and 30 days."
  }
}

variable "tags" {
  description = "Additional tags applied to bootstrap resources"
  type        = map(string)
  default     = {}
}

variable "cloudwatch_logs_kms_key_arn" {
  description = "KMS key ARN used to encrypt the bootstrap audit CloudWatch log group"
  type        = string
  default     = null
}