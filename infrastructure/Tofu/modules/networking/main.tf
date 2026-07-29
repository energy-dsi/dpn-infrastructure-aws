locals {
  name_prefix = "${var.project_name}-${var.environment}"
  az_map      = { for idx, az in var.azs : az => idx }

  vpc_id = var.use_existing_vpc ? var.existing_vpc_id : aws_vpc.this[0].id

  internet_gateway_id = var.create_igw ? aws_internet_gateway.this[0].id : var.existing_internet_gateway_id

  use_internet_gateway = (
    var.create_igw ||
    var.existing_internet_gateway_id != null
  )
}

resource "aws_vpc" "this" {
  count = var.use_existing_vpc ? 0 : 1

  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    Name = "vpc-${local.name_prefix}-${var.aws_region}"
  })
}

resource "aws_internet_gateway" "this" {
  count = var.create_igw ? 1 : 0

  vpc_id = local.vpc_id

  tags = merge(var.tags, {
    Name = "igw-${local.name_prefix}-${var.aws_region}"
  })
}

resource "aws_subnet" "public" {
  for_each = local.az_map

  vpc_id                  = local.vpc_id
  availability_zone       = each.key
  cidr_block              = var.subnet_cidrs.public[each.value]
  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name                                                                                 = "sn-${var.project_name}-public-${replace(each.key, var.aws_region, "")}-${var.environment}"
    Tier                                                                                 = "public"
    "kubernetes.io/role/elb"                                                             = "1"
    "kubernetes.io/cluster/eks-${var.project_name}-${var.environment}-${var.aws_region}" = "shared"
  })
}

resource "aws_subnet" "app" {
  for_each = local.az_map

  vpc_id                  = local.vpc_id
  availability_zone       = each.key
  cidr_block              = var.subnet_cidrs.app[each.value]
  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name                                                                                 = "sn-${var.project_name}-app-${replace(each.key, var.aws_region, "")}-${var.environment}"
    Tier                                                                                 = "application"
    "kubernetes.io/role/internal-elb"                                                    = "1"
    "kubernetes.io/cluster/eks-${var.project_name}-${var.environment}-${var.aws_region}" = "shared"
  })
}

resource "aws_subnet" "mgmt" {
  for_each = local.az_map

  vpc_id                  = local.vpc_id
  availability_zone       = each.key
  cidr_block              = var.subnet_cidrs.mgmt[each.value]
  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name = "sn-${var.project_name}-mgmt-${replace(each.key, var.aws_region, "")}-${var.environment}"
    Tier = "management"
  })
}

resource "aws_subnet" "data" {
  for_each = local.az_map

  vpc_id                  = local.vpc_id
  availability_zone       = each.key
  cidr_block              = var.subnet_cidrs.data[each.value]
  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name = "sn-${var.project_name}-data-${replace(each.key, var.aws_region, "")}-${var.environment}"
    Tier = "data"
  })
}

resource "aws_eip" "nat" {
  for_each = var.create_nat ? local.az_map : {}

  domain = "vpc"

  tags = merge(var.tags, {
    Name = "eip-${var.project_name}-nat-${replace(each.key, var.aws_region, "")}-${var.environment}"
  })
}

resource "aws_nat_gateway" "this" {
  for_each = var.create_nat ? local.az_map : {}

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id

  tags = merge(var.tags, {
    Name = "nat-${var.project_name}-${replace(each.key, var.aws_region, "")}-${var.environment}"
  })

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "public" {
  for_each = local.az_map

  vpc_id = local.vpc_id

  dynamic "route" {
    for_each = local.use_internet_gateway ? [1] : []

    content {
      cidr_block = "0.0.0.0/0"
      gateway_id = local.internet_gateway_id
    }
  }

  dynamic "route" {
    for_each = local.use_internet_gateway ? [] : [1]

    content {
      cidr_block         = "0.0.0.0/0"
      transit_gateway_id = var.transit_gateway_id
    }
  }

  tags = merge(var.tags, {
    Name = "rt-${var.project_name}-public-${replace(each.key, var.aws_region, "")}-${var.environment}"
    Tier = "public"
  })
}

resource "aws_route_table" "application" {
  for_each = local.az_map

  vpc_id = local.vpc_id

  dynamic "route" {
    for_each = var.create_nat ? [1] : []

    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.this[each.key].id
    }
  }

  dynamic "route" {
    for_each = var.create_nat ? [] : [1]

    content {
      cidr_block         = "0.0.0.0/0"
      transit_gateway_id = var.transit_gateway_id
    }
  }

  tags = merge(var.tags, {
    Name = "rt-${var.project_name}-app-${replace(each.key, var.aws_region, "")}-${var.environment}"
    Tier = "application"
  })
}

resource "aws_route_table" "management" {
  for_each = local.az_map

  vpc_id = local.vpc_id

  route {
    cidr_block         = "0.0.0.0/0"
    transit_gateway_id = var.transit_gateway_id
  }

  tags = merge(var.tags, {
    Name = "rt-${var.project_name}-mgmt-${replace(each.key, var.aws_region, "")}-${var.environment}"
    Tier = "management"
  })
}

resource "aws_route_table" "data" {
  for_each = local.az_map

  vpc_id = local.vpc_id

  route {
    cidr_block         = "0.0.0.0/0"
    transit_gateway_id = var.transit_gateway_id
  }

  tags = merge(var.tags, {
    Name = "rt-${var.project_name}-data-${replace(each.key, var.aws_region, "")}-${var.environment}"
    Tier = "data"
  })
}

resource "aws_route_table_association" "public" {
  for_each = local.az_map

  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public[each.key].id
}

resource "aws_route_table_association" "application" {
  for_each = local.az_map

  subnet_id      = aws_subnet.app[each.key].id
  route_table_id = aws_route_table.application[each.key].id
}

resource "aws_route_table_association" "management" {
  for_each = local.az_map

  subnet_id      = aws_subnet.mgmt[each.key].id
  route_table_id = aws_route_table.management[each.key].id
}

resource "aws_route_table_association" "data" {
  for_each = local.az_map

  subnet_id      = aws_subnet.data[each.key].id
  route_table_id = aws_route_table.data[each.key].id
}

resource "aws_network_acl" "public" {
  vpc_id     = local.vpc_id
  subnet_ids = [for az in var.azs : aws_subnet.public[az].id]

  # Deny inbound SSH from all IPv4 sources.
  # This rule is evaluated before the general allow rule.
  ingress {
    protocol   = "6"
    rule_no    = 80
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }

  # Deny inbound RDP from all IPv4 sources.
  # This rule is evaluated before the general allow rule.
  ingress {
    protocol   = "6"
    rule_no    = 90
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    from_port  = 3389
    to_port    = 3389
  }

  # Allow all other inbound IPv4 traffic.
  # Security groups provide the workload-level filtering.
  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  # Allow all outbound IPv4 traffic.
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge(var.tags, {
    Name = "nacl-${var.project_name}-public-${var.environment}"
    Tier = "public"
  })
}

resource "aws_security_group" "node" {
  name        = "${var.project_name}-eks-node-${var.environment}"
  description = "EKS node security group"
  vpc_id      = local.vpc_id

  tags = merge(var.tags, {
    Name = "sg-${var.project_name}-eks-node-${var.environment}"
  })
}

resource "aws_vpc_security_group_ingress_rule" "node_self" {
  security_group_id            = aws_security_group.node.id
  ip_protocol                  = "-1"
  referenced_security_group_id = aws_security_group.node.id
}

resource "aws_vpc_security_group_egress_rule" "node_egress_all" {
  security_group_id = aws_security_group.node.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

locals {
  private_eks_interface_endpoint_services = toset([
    "ec2",
    "eks",
    "sts",
    "ecr.api",
    "ecr.dkr",
    "logs",
    "ssm",
    "ssmmessages",
    "ec2messages",
    "elasticloadbalancing"
  ])

  enabled_interface_endpoint_services = var.enable_vpc_endpoints ? local.private_eks_interface_endpoint_services : toset([])
}

resource "aws_security_group" "vpc_endpoints" {
  count = var.enable_vpc_endpoints ? 1 : 0

  name        = "${var.project_name}-vpce-${var.environment}"
  description = "Security group for private AWS API interface endpoints"
  vpc_id      = local.vpc_id

  tags = merge(var.tags, {
    Name = "sg-${var.project_name}-vpce-${var.environment}"
  })
}

resource "aws_vpc_security_group_ingress_rule" "vpc_endpoints_from_vpc_https" {
  count = var.enable_vpc_endpoints ? 1 : 0

  security_group_id = aws_security_group.vpc_endpoints[0].id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = var.vpc_cidr
}

resource "aws_vpc_security_group_egress_rule" "vpc_endpoints_all_egress" {
  count = var.enable_vpc_endpoints ? 1 : 0

  security_group_id = aws_security_group.vpc_endpoints[0].id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_endpoint" "private_eks_interface" {
  for_each = local.enabled_interface_endpoint_services

  vpc_id              = local.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.${each.key}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [for az in var.azs : aws_subnet.app[az].id]
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name = "vpce-${var.project_name}-${var.environment}-${replace(each.key, ".", "-")}"
  })
}

resource "aws_vpc_endpoint" "s3_gateway" {
  count = var.enable_vpc_endpoints ? 1 : 0

  vpc_id            = local.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = concat(
    [for az in var.azs : aws_route_table.application[az].id],
    [for az in var.azs : aws_route_table.management[az].id],
    [for az in var.azs : aws_route_table.data[az].id]
  )

  tags = merge(var.tags, {
    Name = "vpce-${var.project_name}-${var.environment}-s3"
  })
}

resource "aws_eip" "nlb" {
  for_each = var.create_nlb_eips ? local.az_map : {}

  domain = "vpc"

  tags = merge(var.tags, {
    Name = "eip-${var.project_name}-nlb-${replace(each.key, var.aws_region, "")}-${var.environment}"
    Tier = "public"
    Use  = "nlb-static-ip"
  })
}

resource "aws_iam_role" "vpc_flow_logs" {
  count = var.enable_vpc_flow_logs ? 1 : 0

  name = "${var.project_name}-vpc-flow-logs-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "vpc-flow-logs.amazonaws.com"
      }

      Action = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "vpc_flow_logs" {
  count = var.enable_vpc_flow_logs ? 1 : 0

  name = "${var.project_name}-vpc-flow-logs-${var.environment}"
  role = aws_iam_role.vpc_flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ]

      Resource = "*"
    }]
  })
}

resource "aws_flow_log" "vpc" {
  count = var.enable_vpc_flow_logs ? 1 : 0

  vpc_id               = local.vpc_id
  traffic_type         = "ALL"
  log_destination_type = "cloud-watch-logs"
  log_destination      = var.vpc_flow_log_group_arn
  iam_role_arn         = aws_iam_role.vpc_flow_logs[0].arn

  tags = merge(var.tags, {
    Name = "${var.project_name}-vpc-flow-logs-${var.environment}"
  })
}