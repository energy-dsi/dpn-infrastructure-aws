

output "tfstate_bucket_name" {
  description = "S3 bucket name for OpenTofu state storage"
  value       = aws_s3_bucket.tfstate.id
}

output "tfstate_bucket_arn" {
  description = "ARN of the S3 bucket for OpenTofu state"
  value       = aws_s3_bucket.tfstate.arn
}

output "tfstate_bucket_region" {
  description = "Region of the S3 bucket for OpenTofu state"
  value       = var.aws_region
}

output "tfstate_dynamodb_table_name" {
  description = "DynamoDB table name for state locking"
  value       = aws_dynamodb_table.tfstate_lock.name
}

output "tfstate_dynamodb_table_arn" {
  description = "ARN of the DynamoDB table for state locking"
  value       = aws_dynamodb_table.tfstate_lock.arn
}

output "tfstate_kms_key_id" {
  description = "KMS key ID used for S3 state encryption"
  value       = aws_kms_key.tfstate.id
}

output "tfstate_kms_key_arn" {
  description = "KMS key ARN used for S3 state encryption"
  value       = aws_kms_key.tfstate.arn
}

output "tfstate_kms_key_alias" {
  description = "KMS key alias used for S3 state encryption"
  value       = aws_kms_alias.tfstate.name
}

output "backend_config" {
  description = "Backend configuration values for the main infrastructure"

  value = {
    bucket         = aws_s3_bucket.tfstate.id
    key            = "${var.environment}/terraform.tfstate"
    region         = var.aws_region
    dynamodb_table = aws_dynamodb_table.tfstate_lock.name
    encrypt        = true
    kms_key_id     = aws_kms_key.tfstate.arn
  }
}

output "backend_config_hcl" {
  description = "Contents for the main infrastructure backend HCL file"

  value = <<-EOT
    bucket         = "${aws_s3_bucket.tfstate.id}"
    key            = "${var.environment}/terraform.tfstate"
    region         = "${var.aws_region}"
    dynamodb_table = "${aws_dynamodb_table.tfstate_lock.name}"
    encrypt        = true
    kms_key_id     = "${aws_kms_key.tfstate.arn}"
  EOT
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch log group used for state audit logs"
  value       = aws_cloudwatch_log_group.tfstate_audit.name
}

output "audit_bucket_name" {
  description = "S3 bucket name used for CloudTrail audit logs when enabled"
  value       = try(aws_s3_bucket.tfstate_audit[0].id, null)
}

output "deployment_summary" {
  description = "Summary of deployed bootstrap resources"

  value = {
    state_storage = {
      bucket     = aws_s3_bucket.tfstate.id
      region     = var.aws_region
      encryption = "AWS KMS (${aws_kms_alias.tfstate.name})"
      versioning = "Enabled"
      logging    = "Enabled"
    }

    state_locking = {
      table                  = aws_dynamodb_table.tfstate_lock.name
      billing_mode           = "On-Demand"
      point_in_time_recovery = "Enabled"
      encryption             = "AWS KMS"
    }

    audit = {
      cloudwatch_log_group = aws_cloudwatch_log_group.tfstate_audit.name
      cloudtrail_enabled   = var.enable_cloudtrail_audit
      audit_bucket         = try(aws_s3_bucket.tfstate_audit[0].id, null)
    }
  }
}