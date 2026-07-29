locals {
  oidc_provider_host = replace(var.oidc_provider_url, "https://", "")
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_host}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_host}:sub"
      values   = ["system:serviceaccount:${var.namespace}:${var.service_account_name}"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "${var.project_name}-${var.environment}-${var.service_account_name}"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = var.tags
}

data "aws_iam_policy_document" "permissions" {
  statement {
    sid    = "ApplicationBucketList"
    effect = "Allow"

    actions = [
      "s3:ListBucket"
    ]

    resources = [
      var.application_bucket_arn
    ]
  }

  statement {
    sid    = "ApplicationBucketObjects"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]

    resources = [
      "${var.application_bucket_arn}/*"
    ]
  }

  dynamic "statement" {
    for_each = length(var.secret_arns) > 0 ? [1] : []

    content {
      sid    = "SecretsManagerRead"
      effect = "Allow"

      actions = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ]

      resources = var.secret_arns
    }
  }
}

resource "aws_iam_policy" "this" {
  name   = "${var.project_name}-${var.environment}-${var.service_account_name}-access"
  policy = data.aws_iam_policy_document.permissions.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}