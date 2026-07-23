locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = var.cluster_role_arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = var.endpoint_public_access_cidrs
    security_group_ids      = [var.node_security_group_id]
  }

  enabled_cluster_log_types = var.cluster_log_types

  access_config {
    authentication_mode                         = var.authentication_mode
    bootstrap_cluster_creator_admin_permissions = var.bootstrap_cluster_creator_admin_permissions
  }

  encryption_config {
    provider {
      key_arn = var.kms_key_arn
    }
    resources = ["secrets"]
  }

  tags = merge(var.tags, {
    Name = var.cluster_name
  })
}

resource "aws_eks_node_group" "system" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = var.system_node_group.name
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.private_subnet_ids

  scaling_config {
    desired_size = var.system_node_group.desired_size
    min_size     = var.system_node_group.min_size
    max_size     = var.system_node_group.max_size
  }

  instance_types = var.system_node_group.instance_types
  ami_type       = "AL2023_x86_64_STANDARD"
  capacity_type  = "ON_DEMAND"

  tags = merge(var.tags, {
    Name = "ng-${local.name_prefix}-system"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eks_node_group" "workload" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = var.workload_node_group.name
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.private_subnet_ids

  scaling_config {
    desired_size = var.workload_node_group.desired_size
    min_size     = var.workload_node_group.min_size
    max_size     = var.workload_node_group.max_size
  }

  instance_types = var.workload_node_group.instance_types
  ami_type       = "AL2023_x86_64_STANDARD"
  capacity_type  = "ON_DEMAND"

  labels = {
    workload = "true"
  }

  tags = merge(var.tags, {
    Name = "ng-${local.name_prefix}-workload"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_openid_connect_provider" "this" {
  count           = 1
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.oidc.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer

  tags = var.tags
}

data "aws_iam_policy_document" "efs_csi_assume_role" {
  count = var.enable_efs_csi_driver ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type = "Federated"

      identifiers = [
        aws_iam_openid_connect_provider.this[0].arn
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.this[0].url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "${replace(aws_iam_openid_connect_provider.this[0].url, "https://", "")}:sub"

      values = [
        "system:serviceaccount:kube-system:efs-csi-*"
      ]
    }
  }
}

resource "aws_iam_role" "efs_csi_driver" {
  count = var.enable_efs_csi_driver ? 1 : 0

  name = "${var.project_name}-${var.environment}-efs-csi-driver"

  assume_role_policy = data.aws_iam_policy_document.efs_csi_assume_role[0].json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "efs_csi_driver" {
  count = var.enable_efs_csi_driver ? 1 : 0

  role = aws_iam_role.efs_csi_driver[0].name

  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
}

resource "aws_eks_access_entry" "this" {
  for_each = var.access_entries

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = each.value.principal_arn
  type          = "STANDARD"

  depends_on = [
    aws_eks_cluster.this
  ]
}

resource "aws_eks_access_policy_association" "this" {
  for_each = var.access_entries

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = each.value.principal_arn
  policy_arn    = each.value.policy_arn

  access_scope {
    type       = each.value.access_scope_type
    namespaces = try(each.value.namespaces, null)
  }

  depends_on = [
    aws_eks_access_entry.this
  ]
}
resource "aws_eks_addon" "cloudwatch_observability" {
  count = var.enable_cloudwatch_observability ? 1 : 0

  cluster_name = aws_eks_cluster.this.name
  addon_name   = "amazon-cloudwatch-observability"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = var.tags
}
resource "aws_eks_addon" "efs_csi_driver" {
  count = var.enable_efs_csi_driver ? 1 : 0

  cluster_name = aws_eks_cluster.this.name
  addon_name   = "aws-efs-csi-driver"

  service_account_role_arn = aws_iam_role.efs_csi_driver[0].arn

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = var.tags

  depends_on = [
    aws_iam_role_policy_attachment.efs_csi_driver,
    aws_eks_node_group.system,
    aws_eks_node_group.workload
  ]
}