data "aws_caller_identity" "current" {}


module "security" {
  source = "./modules/security"

  project_name                   = var.project_name
  environment                    = var.environment
  aws_region                     = var.aws_region
  enable_s3_malware_protection   = var.enable_s3_malware_protection
  malware_protection_bucket_name = var.application_bucket_name
  tags                           = var.tags
}

module "observability" {
  source = "./modules/observability"

  project_name          = var.project_name
  environment           = var.environment
  log_retention_in_days = var.log_retention_in_days
  kms_key_arn           = module.security.kms_key_arn
  create_log_s3_buckets = var.create_log_s3_buckets
  tags                  = var.tags
}

module "networking" {
  source = "./modules/networking"

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region
  vpc_cidr     = var.vpc_cidr
  azs          = var.azs
  subnet_cidrs = var.subnet_cidrs

  allowed_egress_fqdns                 = var.allowed_egress_fqdns
  enable_vpc_endpoints                 = var.enable_vpc_endpoints
  enable_restrictive_endpoint_policies = var.enable_restrictive_endpoint_policies
  enable_vpc_flow_logs                 = var.enable_vpc_flow_logs
  enable_network_firewall_logging      = var.enable_network_firewall_logging

  vpc_flow_log_group_arn       = module.observability.vpc_flow_log_group_arn
  firewall_flow_log_group_arn  = module.observability.firewall_flow_log_group_arn
  firewall_alert_log_group_arn = module.observability.firewall_alert_log_group_arn

  use_existing_vpc   = var.use_existing_vpc
  existing_vpc_id    = var.existing_vpc_id
  create_igw         = var.create_igw
  create_nat         = var.create_nat
  transit_gateway_id = var.transit_gateway_id
  create_nlb_eips    = var.create_nlb_eips

  tags = var.tags
}

module "container_registry" {
  source = "./modules/container_registry"

  project_name = var.project_name
  environment  = var.environment
  kms_key_arn  = module.security.kms_key_arn

  image_tag_mutability = var.ecr_image_tag_mutability
  scan_on_push         = var.ecr_scan_on_push

  tags = var.tags

  depends_on = [
    module.security
  ]
}

module "storage" {
  source = "./modules/storage"

  bucket_name             = var.data_bucket_name
  application_bucket_name = var.application_bucket_name
  kms_key_arn             = module.security.kms_key_arn

  force_destroy                      = var.data_bucket_force_destroy
  noncurrent_version_expiration_days = var.data_bucket_noncurrent_version_expiration_days

  tags = var.tags

  depends_on = [
    module.security
  ]
}

module "management_host_iam" {
  source = "./modules/management_host_iam"

  project_name = var.project_name
  environment  = var.environment
  tags         = var.tags
}

module "eks" {
  source = "./modules/eks"

  project_name                                = var.project_name
  environment                                 = var.environment
  cluster_name                                = var.cluster_name
  kubernetes_version                          = var.kubernetes_version
  private_subnet_ids                          = module.networking.application_subnet_ids
  node_security_group_id                      = module.networking.node_security_group_id
  cluster_role_arn                            = module.security.eks_cluster_role_arn
  node_role_arn                               = module.security.eks_node_role_arn
  kms_key_arn                                 = module.security.kms_key_arn
  endpoint_private_access                     = var.endpoint_private_access
  endpoint_public_access                      = var.endpoint_public_access
  endpoint_public_access_cidrs                = var.endpoint_public_access_cidrs
  cluster_log_types                           = var.cluster_log_types
  authentication_mode                         = var.eks_authentication_mode
  bootstrap_cluster_creator_admin_permissions = var.eks_bootstrap_cluster_creator_admin_permissions
  access_entries                              = var.eks_access_entries
  enable_cloudwatch_observability             = var.enable_cloudwatch_observability
  enable_efs_csi_driver                       = var.enable_efs_csi_driver


  system_node_group = {
    name           = var.system_node_group_name
    instance_types = var.system_node_group_instance_types
    desired_size   = var.system_node_group_desired_size
    min_size       = var.system_node_group_min_size
    max_size       = var.system_node_group_max_size
  }

  workload_node_group = {
    name           = var.workload_node_group_name
    instance_types = var.workload_node_group_instance_types
    desired_size   = var.workload_node_group_desired_size
    min_size       = var.workload_node_group_min_size
    max_size       = var.workload_node_group_max_size
  }

  depends_on = [
    module.networking,
    module.security,
    module.observability,
    module.management_host_iam
  ]
}

module "management_host" {
  source = "./modules/management_host"

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region

  vpc_id    = module.networking.vpc_id
  subnet_id = module.networking.management_subnet_ids[0]

  cluster_name              = module.eks.cluster_name
  iam_instance_profile_name = module.management_host_iam.instance_profile_name

  tags = var.tags

  depends_on = [
    module.eks,
    module.networking,
    module.management_host_iam
  ]
}

resource "aws_vpc_security_group_ingress_rule" "management_host_to_eks_api" {
  description                  = "Allow management host to reach private EKS API endpoint"
  security_group_id            = module.eks.cluster_security_group_id
  referenced_security_group_id = module.management_host.security_group_id
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
}

resource "aws_vpc_security_group_ingress_rule" "eks_cluster_sg_nlb_ip_mode_http_from_vpc" {
  description       = "Allow NLB IP-mode HTTP traffic from VPC"
  security_group_id = module.eks.cluster_security_group_id
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = var.vpc_cidr
}

resource "aws_vpc_security_group_ingress_rule" "eks_cluster_sg_nlb_ip_mode_https_from_vpc" {
  description       = "Allow NLB IP-mode HTTPS traffic from VPC"
  security_group_id = module.eks.cluster_security_group_id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = var.vpc_cidr
}

resource "aws_vpc_security_group_ingress_rule" "eks_cluster_sg_nodeport_from_vpc" {
  description       = "Allow NLB instance-mode NodePort traffic from VPC"
  security_group_id = module.eks.cluster_security_group_id
  ip_protocol       = "tcp"
  from_port         = 30000
  to_port           = 32767
  cidr_ipv4         = var.vpc_cidr
}

module "aws_load_balancer_controller_irsa" {
  source = "./modules/aws_load_balancer_controller_irsa"

  project_name      = var.project_name
  environment       = var.environment
  aws_region        = var.aws_region
  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_issuer_url   = module.eks.oidc_issuer_url
  tags              = var.tags

  depends_on = [
    module.eks
  ]
}

module "kubernetes_platform" {
  count  = var.enable_kubernetes_platform ? 1 : 0
  source = "./modules/kubernetes_platform"

  application_namespace        = var.application_namespace
  cluster_name                 = module.eks.cluster_name
  aws_region                   = var.aws_region
  vpc_id                       = module.networking.vpc_id
  alb_controller_role_arn      = module.aws_load_balancer_controller_irsa.iam_role_arn
  alb_controller_chart_version = var.alb_controller_chart_version
  alb_controller_image_tag     = var.alb_controller_image_tag
  tags                         = var.tags

  depends_on = [
    module.eks,
    module.aws_load_balancer_controller_irsa,
    aws_vpc_security_group_ingress_rule.management_host_to_eks_api
  ]
}

module "app_irsa" {
  source = "./modules/app_irsa"

  project_name           = var.project_name
  environment            = var.environment
  oidc_provider_arn      = module.eks.oidc_provider_arn
  oidc_provider_url      = module.eks.oidc_issuer_url
  application_bucket_arn = module.storage.application_bucket_arn
  secret_arns            = var.application_secret_arns
  tags                   = var.tags

  depends_on = [
    module.eks,
    module.storage
  ]
}

module "efs" {
  source = "./modules/efs"

  project_name = var.project_name
  environment  = var.environment

  vpc_id     = module.networking.vpc_id
  subnet_ids = module.networking.application_subnet_ids

  node_security_group_id = module.eks.cluster_security_group_id
  kms_key_arn            = module.security.kms_key_arn
  tags                   = var.tags

  depends_on = [
    module.eks,
    module.networking,
    module.security
  ]
}