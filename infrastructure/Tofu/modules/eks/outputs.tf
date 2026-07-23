output "cluster_name" {
  value = aws_eks_cluster.this.name
}

output "cluster_arn" {
  value = aws_eks_cluster.this.arn
}

output "cluster_endpoint" {
  value = aws_eks_cluster.this.endpoint
}

output "oidc_provider_arn" {
  value = try(aws_iam_openid_connect_provider.this[0].arn, null)
}

output "oidc_issuer_url" {
  value = aws_eks_cluster.this.identity[0].oidc[0].issuer
}


output "access_entry_principal_arns" {
  value = {
    for key, entry in aws_eks_access_entry.this : key => entry.principal_arn
  }
}


output "cluster_security_group_id" {
  description = "EKS cluster security group ID"
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}


output "cluster_certificate_authority_data" {
  description = "Base64 encoded EKS cluster certificate authority data"
  value       = aws_eks_cluster.this.certificate_authority[0].data
}
output "efs_csi_driver_role_arn" {
  value = try(aws_iam_role.efs_csi_driver[0].arn, null)
}
