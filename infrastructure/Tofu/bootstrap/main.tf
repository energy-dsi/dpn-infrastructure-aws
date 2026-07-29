
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = merge(
      var.tags,
      {
        Environment = var.environment
        Project     = var.project_name
        ManagedBy   = "OpenTofu"
        Bootstrap   = "true"
      }
    )
  }
}

data "aws_caller_identity" "current" {}

locals {
  tfstate_kms_alias_name = "alias/${var.project_name}-tfstate-${var.environment}"
  cloudtrail_name        = "${var.project_name}-tfstate-trail-${var.environment}"
}

# ==============================================================================
# KMS Key for State Encryption
# ==============================================================================
data "aws_iam_policy_document" "tfstate_kms" {
  statement {
    sid    = "EnableIAMUserPermissions"
    effect = "Allow"

    principals {
      type = "AWS"

      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowCloudTrailEncryptLogs"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions = [
      "kms:GenerateDataKey*"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"

      values = [
        "arn:aws:cloudtrail:${var.aws_region}:${data.aws_caller_identity.current.account_id}:trail/${local.cloudtrail_name}"
      ]
    }

    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:cloudtrail:arn"

      values = [
        "arn:aws:cloudtrail:*:${data.aws_caller_identity.current.account_id}:trail/*"
      ]
    }
  }

  statement {
    sid    = "AllowCloudTrailDescribeKey"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions = [
      "kms:DescribeKey"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"

      values = [
        "arn:aws:cloudtrail:${var.aws_region}:${data.aws_caller_identity.current.account_id}:trail/${local.cloudtrail_name}"
      ]
    }
  }
}

resource "aws_kms_key" "tfstate" {
  description             = "KMS key for encrypting ${var.project_name} ${var.environment} OpenTofu state"
  deletion_window_in_days = var.kms_key_deletion_window_days
  enable_key_rotation     = true

  policy = data.aws_iam_policy_document.tfstate_kms.json

  tags = {
    Name = "${var.project_name}-tfstate-${var.environment}"
  }
}

resource "aws_kms_alias" "tfstate" {
  name          = "alias/${var.project_name}-tfstate-${var.environment}"
  target_key_id = aws_kms_key.tfstate.key_id
}

# ==============================================================================
# S3 Bucket for OpenTofu State
# ==============================================================================

resource "aws_s3_bucket" "tfstate" {
  bucket = var.tfstate_bucket_name

  tags = {
    Name = var.tfstate_bucket_name
  }
}

resource "aws_s3_bucket_ownership_controls" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  versioning_configuration {
    status     = "Enabled"
    mfa_delete = "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.tfstate.arn
    }

    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ==============================================================================
# S3 Bucket for State-Bucket Access Logs
# ==============================================================================

resource "aws_s3_bucket" "tfstate_logs" {
  bucket = "${var.tfstate_bucket_name}-logs"

  tags = {
    Name = "${var.tfstate_bucket_name}-logs"
  }
}

resource "aws_s3_bucket_ownership_controls" "tfstate_logs" {
  bucket = aws_s3_bucket.tfstate_logs.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "tfstate_logs" {
  bucket = aws_s3_bucket.tfstate_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate_logs" {
  bucket = aws_s3_bucket.tfstate_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate_logs" {
  bucket = aws_s3_bucket.tfstate_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "tfstate_logs" {
  bucket = aws_s3_bucket.tfstate_logs.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "AllowS3ServerAccessLogDelivery"
        Effect = "Allow"

        Principal = {
          Service = "logging.s3.amazonaws.com"
        }

        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.tfstate_logs.arn}/tfstate-access-logs/*"

        Condition = {
          ArnLike = {
            "aws:SourceArn" = aws_s3_bucket.tfstate.arn
          }

          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"

        Resource = [
          aws_s3_bucket.tfstate_logs.arn,
          "${aws_s3_bucket.tfstate_logs.arn}/*"
        ]

        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })

  depends_on = [
    aws_s3_bucket_ownership_controls.tfstate_logs,
    aws_s3_bucket_public_access_block.tfstate_logs
  ]
}

resource "aws_s3_bucket_logging" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  target_bucket = aws_s3_bucket.tfstate_logs.id
  target_prefix = "tfstate-access-logs/"

  depends_on = [
    aws_s3_bucket_policy.tfstate_logs
  ]
}

resource "aws_s3_bucket_lifecycle_configuration" "tfstate_logs" {
  bucket = aws_s3_bucket.tfstate_logs.id

  rule {
    id     = "delete-old-access-logs"
    status = "Enabled"

    filter {}

    expiration {
      days = 90
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.tfstate_logs
  ]
}


resource "aws_s3_bucket_policy" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid       = "DenyUnencryptedObjectUploads"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.tfstate.arn}/*"

        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "aws:kms"
          }
        }
      },
      {
        Sid       = "DenyIncorrectKmsKey"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.tfstate.arn}/*"

        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption-aws-kms-key-id" = aws_kms_key.tfstate.arn
          }
        }
      },
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"

        Resource = [
          aws_s3_bucket.tfstate.arn,
          "${aws_s3_bucket.tfstate.arn}/*"
        ]

        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })

  depends_on = [
    aws_s3_bucket_ownership_controls.tfstate,
    aws_s3_bucket_public_access_block.tfstate,
    aws_s3_bucket_server_side_encryption_configuration.tfstate
  ]
}



resource "aws_dynamodb_table" "tfstate_lock" {
  name         = var.tfstate_dynamodb_table
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.tfstate.arn
  }

  tags = {
    Name = var.tfstate_dynamodb_table
  }
}



resource "aws_cloudwatch_log_group" "tfstate_audit" {
  name              = "/aws/tfstate/${var.environment}/audit"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.cloudwatch_logs_kms_key_arn

  tags = {
    Name = "${var.project_name}-tfstate-audit-${var.environment}"
  }
}



resource "aws_s3_bucket" "tfstate_audit" {
  count = var.enable_cloudtrail_audit ? 1 : 0

  bucket = "${var.tfstate_bucket_name}-audit"

  tags = {
    Name = "${var.tfstate_bucket_name}-audit"
  }
}

resource "aws_s3_bucket_ownership_controls" "tfstate_audit" {
  count = var.enable_cloudtrail_audit ? 1 : 0

  bucket = aws_s3_bucket.tfstate_audit[0].id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "tfstate_audit" {
  count = var.enable_cloudtrail_audit ? 1 : 0

  bucket = aws_s3_bucket.tfstate_audit[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate_audit" {
  count = var.enable_cloudtrail_audit ? 1 : 0

  bucket = aws_s3_bucket.tfstate_audit[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate_audit" {
  count = var.enable_cloudtrail_audit ? 1 : 0

  bucket = aws_s3_bucket.tfstate_audit[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "tfstate_audit" {
  count = var.enable_cloudtrail_audit ? 1 : 0

  bucket = aws_s3_bucket.tfstate_audit[0].id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"

        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }

        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.tfstate_audit[0].arn

        Condition = {
          StringEquals = {
            "aws:SourceArn" = "arn:aws:cloudtrail:${var.aws_region}:${data.aws_caller_identity.current.account_id}:trail/${local.cloudtrail_name}"
          }
        }
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"

        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }

        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.tfstate_audit[0].arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"

        Condition = {
          StringEquals = {
            "s3:x-amz-acl"  = "bucket-owner-full-control"
            "aws:SourceArn" = "arn:aws:cloudtrail:${var.aws_region}:${data.aws_caller_identity.current.account_id}:trail/${local.cloudtrail_name}"
          }
        }
      },
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"

        Resource = [
          aws_s3_bucket.tfstate_audit[0].arn,
          "${aws_s3_bucket.tfstate_audit[0].arn}/*"
        ]

        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })

  depends_on = [
    aws_s3_bucket_ownership_controls.tfstate_audit,
    aws_s3_bucket_public_access_block.tfstate_audit,
    aws_s3_bucket_server_side_encryption_configuration.tfstate_audit
  ]
}

resource "aws_s3_bucket_logging" "tfstate_audit" {
  count = var.enable_cloudtrail_audit ? 1 : 0

  bucket = aws_s3_bucket.tfstate_audit[0].id

  target_bucket = aws_s3_bucket.tfstate_logs.id
  target_prefix = "cloudtrail-audit-access-logs/"

  depends_on = [
    aws_s3_bucket_policy.tfstate_logs
  ]
}

resource "aws_cloudtrail" "tfstate" {
  count = var.enable_cloudtrail_audit ? 1 : 0

  name                          = local.cloudtrail_name
  s3_bucket_name                = aws_s3_bucket.tfstate_audit[0].id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  kms_key_id                    = aws_kms_key.tfstate.arn

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type = "AWS::S3::Object"

      values = [
        "${aws_s3_bucket.tfstate.arn}/"
      ]
    }

    data_resource {
      type = "AWS::DynamoDB::Table"

      values = [
        aws_dynamodb_table.tfstate_lock.arn
      ]
    }
  }

  depends_on = [
    aws_s3_bucket_policy.tfstate_audit
  ]

  tags = {
    Name = local.cloudtrail_name
  }
}