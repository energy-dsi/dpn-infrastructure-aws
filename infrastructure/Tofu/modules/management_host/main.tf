data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "this" {
  name        = "${var.project_name}-mgmt-host-${var.environment}"
  description = "Private management host for Kubernetes and platform administration"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.project_name}-mgmt-host-${var.environment}"
  })
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.this.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_instance" "this" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.this.id]
  iam_instance_profile        = var.iam_instance_profile_name
  associate_public_ip_address = false

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  user_data_replace_on_change = true

  user_data = <<-EOF
    #!/bin/bash
    set -euxo pipefail

    dnf install -y \
      unzip \
      tar \
      gzip \
      jq \
      git

    curl -fsSL \
      -o /usr/local/bin/kubectl \
      "https://s3.us-west-2.amazonaws.com/amazon-eks/1.35.0/2026-01-15/bin/linux/amd64/kubectl"

    chmod 0755 /usr/local/bin/kubectl
  EOF

  tags = merge(var.tags, {
    Name = "${var.project_name}-mgmt-host-${var.environment}"
  })
}