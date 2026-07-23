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
}

resource "aws_security_group" "this" {
  name        = "${var.project_name}-mgmt-host-${var.environment}"
  description = "Private management host for kubectl and platform administration"
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

resource "aws_iam_role" "this" {
  name = "${var.project_name}-mgmt-host-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "eks_describe" {

  name = "${var.project_name}-mgmt-host-eks-describe-${var.environment}"

  role = aws_iam_role.this.id

  policy = jsonencode({

    Version = "2012-10-17"

    Statement = [{

      Effect = "Allow"

      Action = [

        "eks:DescribeCluster",

        "eks:ListClusters",

        "ecr:DescribeRepositories",

        "ecr:GetAuthorizationToken",

        "ecr:BatchCheckLayerAvailability",

        "ecr:GetDownloadUrlForLayer",

        "ecr:BatchGetImage"

      ]

      Resource = "*"

    }]

  })

}
resource "aws_iam_role_policy" "tools_bucket_read" {
  name = "${var.project_name}-mgmt-host-tools-bucket-read-${var.environment}"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject"
      ]
      Resource = "arn:aws:s3:::${var.project_name}-${var.environment}-data/tools/*"
    }]
  })
}
resource "aws_iam_role_policy" "tools_bucket_kms_decrypt" {
  name = "${var.project_name}-mgmt-host-tools-kms-decrypt-${var.environment}"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "kms:Decrypt"
      ]
      Resource = "arn:aws:kms:eu-west-2:627657103820:key/e9d838f3-c06e-480f-801d-2befa38b98f5"
    }]
  })
}
resource "aws_iam_instance_profile" "this" {
  name = "${var.project_name}-mgmt-host-${var.environment}"
  role = aws_iam_role.this.name
}

resource "aws_instance" "this" {
  ami                         = "ami-07c06c9f04a3f051f"
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.this.id]
  iam_instance_profile        = aws_iam_instance_profile.this.name
  associate_public_ip_address = false

  metadata_options {
    http_tokens = "required"
  }

  user_data = <<-EOF
    #!/bin/bash
    set -eux

    dnf install -y unzip tar gzip jq

    aws eks update-kubeconfig \
      --region ${var.aws_region} \
      --name ${var.cluster_name} \
      --kubeconfig /root/.kube/config
  EOF

  tags = merge(var.tags, {
    Name = "${var.project_name}-mgmt-host-${var.environment}"
  })
}

resource "aws_iam_role_policy" "s3_data_bucket_access" {
  name = "${var.project_name}-mgmt-host-s3-data-${var.environment}"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = "arn:aws:s3:::${var.data_bucket_name}"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "arn:aws:s3:::${var.data_bucket_name}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]
        Resource = var.kms_key_arn
      }
    ]
  })
}
resource "aws_iam_role_policy" "terraform_backend_access" {
  name = "${var.project_name}-mgmt-host-terraform-backend-${var.environment}"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = "arn:aws:s3:::dpn-tfstate-dev-001"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "arn:aws:s3:::dpn-tfstate-dev-001/*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:DescribeTable"
        ]
        Resource = "arn:aws:dynamodb:eu-west-2:627657103820:table/dpn-tfstate-lock-dev"
      }
    ]
  })
}