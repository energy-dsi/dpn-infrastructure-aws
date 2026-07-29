output "vpc_id" {
  description = "VPC ID"
  value       = local.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public or ingress subnets"
  value       = [for az in var.azs : aws_subnet.public[az].id]
}

output "application_subnet_ids" {
  description = "IDs of the application and EKS worker subnets"
  value       = [for az in var.azs : aws_subnet.app[az].id]
}

output "data_subnet_ids" {
  description = "IDs of the data and RDS subnets"
  value       = [for az in var.azs : aws_subnet.data[az].id]
}

output "management_subnet_ids" {
  description = "IDs of the management subnets"
  value       = [for az in var.azs : aws_subnet.mgmt[az].id]
}

output "alb_security_group_id" {
  description = "ALB security group ID. Null because the ALB security group is managed outside this networking module."
  value       = null
}

output "node_security_group_id" {
  description = "EKS node security group ID"
  value       = aws_security_group.node.id
}

output "data_security_group_id" {
  description = "Data security group ID. Null because data-tier access is managed outside this networking module."
  value       = null
}

output "management_security_group_id" {
  description = "Management security group ID. Null because the management-host module manages its own security group."
  value       = null
}

output "transit_gateway_id" {
  description = "Transit Gateway ID used for subnet egress routing"
  value       = var.transit_gateway_id
}

output "network_firewall_arn" {
  description = "Network Firewall ARN. Null because no VPC Network Firewall is provisioned in this deployment."
  value       = null
}

output "interface_vpc_endpoint_ids" {
  description = "Map of interface VPC endpoint service names to endpoint IDs"
  value = {
    for service, endpoint in aws_vpc_endpoint.private_eks_interface :
    service => endpoint.id
  }
}

output "s3_gateway_vpc_endpoint_id" {
  description = "S3 gateway VPC endpoint ID"
  value       = try(aws_vpc_endpoint.s3_gateway[0].id, null)
}

output "nlb_eip_allocation_ids" {
  description = "Elastic IP allocation IDs ordered according to var.azs."
  value = var.create_nlb_eips ? [
    for az in var.azs : aws_eip.nlb[az].allocation_id
  ] : []
}

output "nlb_eip_allocation_ids_by_az" {
  description = "Elastic IP allocation IDs mapped by Availability Zone."
  value = var.create_nlb_eips ? {
    for az in var.azs : az => aws_eip.nlb[az].allocation_id
  } : {}
}

output "nlb_public_ips" {
  description = "Static public IPv4 addresses ordered according to var.azs."
  value = var.create_nlb_eips ? [
    for az in var.azs : aws_eip.nlb[az].public_ip
  ] : []
}