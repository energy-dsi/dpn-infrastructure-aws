locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

resource "aws_security_group" "efs" {
  name        = "${local.name_prefix}-efs"
  description = "Allow NFS access from EKS worker nodes"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-efs"
  })
}

resource "aws_vpc_security_group_ingress_rule" "efs_from_nodes" {
  security_group_id            = aws_security_group.efs.id
  referenced_security_group_id = var.node_security_group_id

  ip_protocol = "tcp"
  from_port   = 2049
  to_port     = 2049
}

resource "aws_vpc_security_group_egress_rule" "efs_all" {
  security_group_id = aws_security_group.efs.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_efs_file_system" "this" {
  creation_token = "${local.name_prefix}-efs"
  encrypted      = true
  kms_key_id     = var.kms_key_arn

  performance_mode = "generalPurpose"
  throughput_mode  = "elastic"

  tags = merge(var.tags, {
    Name      = "${local.name_prefix}-efs"
    Component = "storage"
  })
}

resource "aws_efs_backup_policy" "this" {
  file_system_id = aws_efs_file_system.this.id

  backup_policy {
    status = "ENABLED"
  }
}

resource "aws_efs_mount_target" "this" {
  for_each = {
    for index, subnet_id in var.subnet_ids :
    tostring(index) => subnet_id
  }

  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = each.value
  security_groups = [aws_security_group.efs.id]
}