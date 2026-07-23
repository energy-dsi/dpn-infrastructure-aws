output "vpc_id" {
  description = "AWS VPC id"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet ids"
  value       = module.networking.public_subnet_ids
}

output "application_subnet_ids" {
  description = "Application subnet ids used by EKS managed node groups"
  value       = module.networking.application_subnet_ids
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS API endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_access_entry_principal_arns" {
  description = "EKS access entry principal ARNs by entry key"
  value       = module.eks.access_entry_principal_arns
}
output "ecr_repository_url" {
  description = "ECR repository URL for application container images."
  value       = module.container_registry.repository_url
}

output "ecr_repository_arn" {
  description = "ECR repository ARN."
  value       = module.container_registry.repository_arn
}

output "data_bucket_name" {
  description = "Private encrypted S3 data bucket name."
  value       = module.storage.bucket_name
}

output "data_bucket_arn" {
  description = "Private encrypted S3 data bucket ARN."
  value       = module.storage.bucket_arn
}
output "management_host_instance_id" {
  value = module.management_host.instance_id
}

output "management_host_private_ip" {
  value = module.management_host.private_ip
}

output "management_host_role_arn" {
  value = module.management_host.iam_role_arn
}
output "aws_load_balancer_controller_role_arn" {
  value = module.aws_load_balancer_controller_irsa.iam_role_arn
}

output "aws_load_balancer_controller_policy_arn" {
  value = module.aws_load_balancer_controller_irsa.iam_policy_arn
}

output "nlb_eip_allocation_ids" {
  description = "Elastic IP allocation IDs for internet-facing NLBs."
  value       = module.networking.nlb_eip_allocation_ids
}

output "nlb_public_ips" {
  description = "Static public IP addresses for internet-facing NLBs."
  value       = module.networking.nlb_public_ips
}

output "application_bucket_name" {
  value = module.storage.application_bucket_name
}

output "application_bucket_arn" {
  value = module.storage.application_bucket_arn
}

output "application_service_account_role_arn" {
  value = module.app_irsa.role_arn
}

output "application_service_account_name" {
  value = module.app_irsa.service_account_name
}

output "efs_file_system_id" {
  description = "EFS file system ID."
  value       = module.efs.file_system_id
}

output "efs_file_system_arn" {
  description = "EFS file system ARN."
  value       = module.efs.file_system_arn
}

output "efs_dns_name" {
  description = "Regional EFS DNS name."
  value       = module.efs.dns_name
}

output "efs_security_group_id" {
  description = "Security group attached to the EFS mount targets."
  value       = module.efs.security_group_id
}

output "guardduty_findings_topic_arn" {
  value = module.security.guardduty_findings_topic_arn
}
