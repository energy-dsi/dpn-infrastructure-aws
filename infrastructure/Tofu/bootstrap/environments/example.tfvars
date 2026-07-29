aws_region  = "eu-west-2"
project_name = "example-platform"
environment  = "example"

# S3 bucket names are globally unique. Replace before deployment.
tfstate_bucket_name    = "example-platform-tfstate-111122223333-eu-west-2"
tfstate_dynamodb_table = "example-platform-tfstate-lock-example"

# Optional KMS key used by CloudWatch Logs. Leave null to use the bootstrap
# module's own state key where supported by the implementation.
cloudwatch_logs_kms_key_arn = null

enable_cloudtrail_audit      = true
log_retention_days           = 30
kms_key_deletion_window_days = 7

tags = {
  project     = "example-platform"
  environment = "example"
  managed_by  = "opentofu"
  bootstrap   = "true"
}
