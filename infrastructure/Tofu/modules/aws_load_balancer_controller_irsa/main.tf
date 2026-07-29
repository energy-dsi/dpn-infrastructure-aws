locals {
  oidc_provider_hostpath = replace(var.oidc_issuer_url, "https://", "")
  service_account_name   = "aws-load-balancer-controller"
  service_account_ns     = "platform"
}

resource "aws_iam_policy" "this" {
  name        = "${var.project_name}-${var.environment}-aws-load-balancer-controller"
  description = "IAM policy for AWS Load Balancer Controller on ${var.cluster_name}"
  policy      = file("${path.module}/iam_policy.json")

  tags = var.tags
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_hostpath}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_hostpath}:sub"
      values   = ["system:serviceaccount:${local.service_account_ns}:${local.service_account_name}"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "${var.project_name}-${var.environment}-aws-load-balancer-controller"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}