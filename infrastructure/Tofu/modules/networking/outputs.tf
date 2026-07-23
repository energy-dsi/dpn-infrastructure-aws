output "vpc_id" {
  description = "VPC id"
  value       = local.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet ids"
  value       = [for az in var.azs : aws_subnet.public[az].id]
}

output "application_subnet_ids" {
  description = "Application subnet ids"
  value       = [for az in var.azs : aws_subnet.app[az].id]
}

output "data_subnet_ids" {
  description = "Data subnet ids. Empty in the minimal EKS-first profile."
  value       = []
}

output "management_subnet_ids" {
  description = "Management subnet ids. Empty in the minimal EKS-first profile."
  value       = []
}

output "alb_security_group_id" {
  description = "ALB security group id. Null in the minimal EKS-first profile."
  value       = null
}

output "node_security_group_id" {
  description = "EKS node security group id"
  value       = aws_security_group.node.id
}

output "data_security_group_id" {
  description = "Data security group id. Null in the minimal EKS-first profile."
  value       = null
}

output "management_security_group_id" {
  description = "Management security group id. Null in the minimal EKS-first profile."
  value       = null
}

output "transit_gateway_id" {
  description = "Transit Gateway id. Null in the minimal EKS-first profile."
  value       = null
}

output "network_firewall_arn" {
  description = "Network Firewall ARN. Null in the minimal EKS-first profile."
  value       = null
}

output "interface_vpc_endpoint_ids" {
  description = "Interface VPC endpoint ids. Empty in the minimal EKS-first profile."
  value       = {}
}

output "s3_gateway_vpc_endpoint_id" {
  description = "S3 gateway VPC endpoint id. Null in the minimal EKS-first profile."
  value       = null
}
output "nlb_eip_allocation_ids" {
  description = "Elastic IP allocation IDs for internet-facing NLBs."
  value       = [for eip in aws_eip.nlb : eip.id]
}

output "nlb_public_ips" {
  description = "Static public IP addresses for internet-facing NLBs."
  value       = [for eip in aws_eip.nlb : eip.public_ip]
}